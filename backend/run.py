import os
import socket
import json
import uvicorn

def get_lan_ip() -> str:
    """Detect local machine LAN IPv4 address for physical mobile device testing."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def is_port_free(host: str, port: int) -> bool:
    """Test whether a port can be bound without throwing permission or in-use errors."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((host, port))
            return True
    except OSError:
        return False

def record_server_info(host: str, port: int, lan_ip: str):
    info_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".active_server_info.json")
    try:
        data = {
            "host": host,
            "port": port,
            "lan_ip": lan_ip,
            "local_api_url": f"http://localhost:{port}/api/v1",
            "lan_api_url": f"http://{lan_ip}:{port}/api/v1",
            "emulator_api_url": f"http://10.0.2.2:{port}/api/v1"
        }
        with open(info_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception:
        pass

if __name__ == "__main__":
    requested_port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    is_dev = os.getenv("ENVIRONMENT", "development").lower() == "development"
    reload_enabled = os.getenv("RELOAD", "true" if is_dev else "false").lower() in ("true", "1")
    
    port = requested_port
    if not is_port_free(host, port):
        # Try fallback port (8001 if 8000 was requested, or 8000 if 8001 was requested)
        alt_port = 8001 if port == 8000 else 8000
        if is_port_free(host, alt_port):
            print(f"[Port Warning] Port {port} is unavailable or reserved (WinError 10013 / in-use).")
            print(f"[Port Recovery] Automatically switching to available port {alt_port}.")
            port = alt_port
        else:
            print(f"[Port Warning] Both port {requested_port} and {alt_port} are in use. Proceeding with {port}.")

    lan_ip = get_lan_ip()
    record_server_info(host, port, lan_ip)

    print("=" * 65)
    print(" Local Skill Exchange Backend Server")
    print(f" • Local Desktop / Web URL:     http://localhost:{port}/api/v1")
    print(f" • Android Physical Device URL:  http://{lan_ip}:{port}/api/v1")
    print(f" • Android Emulator URL:         http://10.0.2.2:{port}/api/v1")
    print(f" • Swagger Docs:                 http://{lan_ip}:{port}/docs")
    print("=" * 65)
    
    uvicorn.run("app.main:app", host=host, port=port, reload=reload_enabled)
