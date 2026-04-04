// deno-lint-ignore-file
// LiveKit Token Edge Function — Deploy to Supabase
// deno deploy: supabase functions deploy livekit-token
import { AccessToken } from 'npm:livekit-server-sdk@^2.0.0'

const LIVEKIT_API_KEY = Deno.env.get('LIVEKIT_API_KEY')!
const LIVEKIT_API_SECRET = Deno.env.get('LIVEKIT_API_SECRET')!
const LIVEKIT_WS_URL = Deno.env.get('LIVEKIT_WS_URL')!

Deno.serve(async (req: Request) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { sessionId, studentId } = await req.json()

    if (!sessionId || !studentId) {
      return new Response(
        JSON.stringify({ error: 'sessionId and studentId are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const token = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: studentId,
    })

    token.addGrant({
      roomJoin: true,
      room: sessionId,
      canPublish: false,        // students never publish
      canSubscribe: true,
      canPublishData: false,    // data goes through Supabase, not LiveKit
    })

    const jwt = await token.toJwt()

    return new Response(
      JSON.stringify({ token: jwt, wsUrl: LIVEKIT_WS_URL }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
