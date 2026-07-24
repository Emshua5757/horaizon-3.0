import os
import sys
import time
import socket
import subprocess

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('127.0.0.1', port)) == 0

def main():
    # Make sure we're in the right directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    print("=========================================================")
    print("     S.H.U.A. DIARY BACKEND ORCHESTRATION ENGINE")
    print("=========================================================\n")

    print("Select Active Execution Pipeline Suite:")
    print("---------------------------------------------------------")
    print("1) Cloud Mode  - Gemini API (Free Tier, Token-Bucket Rate-Limited)")
    print("2) Local Mode  - Ollama LLM (Offline-First, Hermes 3 & Qwen 2.5)")
    print("3) Hybrid Mode - Python IPC Analyzer & Ollama Chat Assistant")
    print("4) Custom Mode - Ask for individual pipeline bindings")
    print("---------------------------------------------------------\n")

    try:
        choice = input("Enter option [1-4] (Default is 2): ").strip()
    except EOFError:
        choice = "2"
        
    if not choice:
        choice = "2"

    env = os.environ.copy()

    if choice == "1":
        env["ANALYZER_PROVIDER"] = "gemini"
        env["ASSISTANT_PROVIDER"] = "gemini"
        print("\n[SYSTEM] Cloud Mode Activated. (Gemini-backed engines configured).")
    elif choice == "2":
        env["ANALYZER_PROVIDER"] = "ollama"
        env["ASSISTANT_PROVIDER"] = "ollama"
        env["OLLAMA_PLANNER_MODEL"] = "jbc-3b"
        print("\n[SYSTEM] Local Mode Activated. (Ollama-backed engines configured with jbc-3b planner).")
    elif choice == "3":
        env["ANALYZER_PROVIDER"] = "python"
        env["ASSISTANT_PROVIDER"] = "ollama"
        env["OLLAMA_PLANNER_MODEL"] = "jbc-3b"
        print("\n[SYSTEM] Hybrid Mode Activated. (Python Analyzer & Ollama Assistant with jbc-3b planner).")
    elif choice == "4":
        print("\n--- Custom Pipeline Configuration ---")
        analyzer = input("Enter ANALYZER_PROVIDER (ollama / gemini / python) [Default: ollama]: ").strip()
        env["ANALYZER_PROVIDER"] = analyzer if analyzer else "ollama"

        assistant = input("Enter ASSISTANT_PROVIDER (ollama / gemini / n8n) [Default: ollama]: ").strip()
        env["ASSISTANT_PROVIDER"] = assistant if assistant else "ollama"

        print(f"\n[SYSTEM] Custom Mode Configured: Analyzer={env['ANALYZER_PROVIDER']}, Assistant={env['ASSISTANT_PROVIDER']}")
    else:
        print("\n[WARNING] Invalid selection. Defaulting to Local Mode.")
        env["ANALYZER_PROVIDER"] = "ollama"
        env["ASSISTANT_PROVIDER"] = "ollama"
        env["OLLAMA_PLANNER_MODEL"] = "jbc-3b"

    processes = []

    # --- Ollama Daemon Auto-Start ---
    if env.get("ASSISTANT_PROVIDER") == "ollama" or env.get("ANALYZER_PROVIDER") == "ollama":
        print("\n[OLLAMA] Checking daemon health on 127.0.0.1:11434...")
        if is_port_in_use(11434):
            print("[OLLAMA] Daemon already running on :11434. Skipping boot.")
        else:
            print("[OLLAMA] Daemon not detected. Launching 'ollama serve' in background...")
            # Detach process so taskkill /T on parent doesn't kill the Ollama daemon
            if sys.platform == "win32":
                subprocess.Popen("ollama serve", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP)
            else:
                subprocess.Popen("ollama serve", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            
            # Poll for up to 10 seconds
            deadline = time.time() + 10.0
            ready = False
            while time.time() < deadline:
                time.sleep(0.5)
                if is_port_in_use(11434):
                    ready = True
                    break
                    
            if ready:
                print("[OLLAMA] Daemon is live on :11434. Proceeding...")
            else:
                print("[OLLAMA] WARNING: Daemon did not bind within 10s. Proceeding anyway.")

    print("\n[BOOT] Starting Node.js dev server...")
    print("---------------------------------------------------------")
    
    # Start the Next.js/Node dev server
    try:
        # Use shell=True for npm to resolve properly on Windows
        p = subprocess.Popen("npm run dev", shell=True, env=env)
        processes.append(p)
        
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[*] Shutting down Node.js server...")
        for p in processes:
            p.terminate()
        for p in processes:
            p.wait()
        print("[+] Shutdown complete.")

if __name__ == "__main__":
    main()
