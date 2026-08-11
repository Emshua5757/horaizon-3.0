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

2. To help quickly debug the problems we might encounter in the future. all erros must include that raw details. For this case we add the raw payload so that we can deduce instead of guessing fallbacks that bloat up the code.
3. next is that i managed to solve the generation of the ai. however it takes too long and usually fails because we could waste time. the reason we are wasting time is that if the first stream is wrong for example, we expect a json and it outupts a thinking block then in the resume no thinking blocks are reqiured, we need an output fast. 
4. if we are asking to just compile the resume,the tool does not need to know about the other mcp tools (the context added might poison the ai)
5. i tried using qwen2.5:1.5b instead of qwen3.5:2b but it outright rejected me becasue i assume that we only support thinking models. which is wrong.