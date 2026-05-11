import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = "gemini-2.0-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

const SYSTEM_INSTRUCTION = `You are a friendly, expert classroom tutor helping students clear their doubts.

CRITICAL RULES:
1. LANGUAGE: The student may write in ANY language (English, Hindi, Kannada, Tamil, Telugu, Malayalam, etc). 
   You MUST detect the language and respond ENTIRELY in the SAME language the student used.
   If they mix languages, respond in the dominant language of their message.

2. EXPLANATIONS: Give clear, concise explanations appropriate for school/college students.
   - Use simple analogies when helpful
   - Break complex topics into digestible steps
   - For math problems, show step-by-step solutions
   - For science, explain the underlying concept first

3. FORMATTING: Keep responses well-structured but not overly long.
   - Use line breaks for readability
   - Avoid markdown formatting (no asterisks, hashtags, etc) — this is a mobile chat
   - Keep answers focused — aim for 3-8 sentences unless the topic needs more

4. TONE: Be encouraging and supportive. Never make the student feel bad for asking.
   Start with a brief acknowledgment of their question when appropriate.

5. SCOPE: You are a general academic tutor. Answer questions about any school/college subject.
   If asked something completely non-academic, gently redirect to academic topics.`;

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const { question, history } = await req.json();

    if (!question || typeof question !== "string" || question.trim() === "") {
      return new Response(
        JSON.stringify({ error: "Question is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Build conversation contents for Gemini
    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    // Add conversation history for context
    if (Array.isArray(history)) {
      for (const msg of history) {
        contents.push({
          role: msg.role === "user" ? "user" : "model",
          parts: [{ text: msg.text }],
        });
      }
    }

    // Add the current question
    contents.push({
      role: "user",
      parts: [{ text: question }],
    });

    // Call Gemini API
    const geminiResponse = await fetch(GEMINI_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: {
          parts: [{ text: SYSTEM_INSTRUCTION }],
        },
        contents,
        generationConfig: {
          temperature: 0.7,
          topP: 0.95,
          topK: 40,
          maxOutputTokens: 1024,
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_ONLY_HIGH" },
          { category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_ONLY_HIGH" },
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error("Gemini API error:", errorText);
      return new Response(
        JSON.stringify({ error: "AI service unavailable. Please try again." }),
        { status: 502, headers: { "Content-Type": "application/json" } }
      );
    }

    const geminiData = await geminiResponse.json();

    // Extract the response text
    const answer =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    if (!answer) {
      return new Response(
        JSON.stringify({ error: "No response generated. Try rephrasing your question." }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ answer }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
