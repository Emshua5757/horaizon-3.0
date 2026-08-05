1. We need to include warn!() so that our flutter cna detect errors in the telemetry, we need to add this to everything inside the shua governor. one thing that helped me debug is
"ai.route" | "governor.ai.route" => {
                let decoded = frame.decode_payload::<AiRouteRequest>();
                if let Err(ref e) = decoded {
                    // Extract raw payload string for inspection
                    let raw_payload_str = String::from_utf8_lossy(&frame.p);
                    warn!(
                        subsystem = "dispatcher",
                        op = %frame.op,
                        error = %e,
                        raw_payload = %raw_payload_str,
                        "❌ CRITICAL: ai.route payload decoding failed! Dumping raw payload above."
                    );
                }

2. To help quickly debug the problems we might encounter in the future. all erros must include that raw details. For this case we add the raw payload so that we can deduce instead of guessing fallbacks that bloat up the code
