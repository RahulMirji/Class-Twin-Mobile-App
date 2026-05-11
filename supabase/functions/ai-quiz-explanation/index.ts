import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

const SYSTEM_INSTRUCTION = `You are an expert tutor giving very short, instant feedback on a quiz question.
Your goal is to explain WHY the correct answer is right. 

CRITICAL RULES:
1. EXTREMELY CONCISE: Provide your explanation in exactly 1-2 very short sentences. Do not ramble.
2. DIRECT AND CLEAR: Explain the core concept that makes the correct answer correct.
3. LANGUAGE MATCHING: You MUST detect the language of the question and provide your explanation entirely in that same language (e.g. English, Hindi, Kannada, Tamil, etc).
4. TONE: Encouraging and educational.
5. NO FORMATTING: Do not use markdown, bolding, or lists. Just plain text.`;

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

    const { question, correctOption, studentAnswer } = await req.json();

    if (!question || !correctOption) {
      return new Response(
        JSON.stringify({ error: "Question and correctOption are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Build conversation contents for Gemini
    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

    let promptText = `Question: ${question}\nCorrect Answer: ${correctOption}\n`;
    if (studentAnswer && studentAnswer !== correctOption) {
      promptText += `Student's Incorrect Answer: ${studentAnswer}\n\nBriefly explain why the Correct Answer is right.`;
    } else {
      promptText += `\nBriefly explain why the Correct Answer is right.`;
    }

    contents.push({
      role: "user",
      parts: [{ text: promptText }],
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
          temperature: 0.3, // Lower temperature for more factual, concise explanations
          topP: 0.95,
          topK: 40,
          maxOutputTokens: 256, // Keep it short
        },
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
    const explanation =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    if (!explanation) {
      return new Response(
        JSON.stringify({ error: "No explanation generated." }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ explanation: explanation.trim() }),
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
