"""Bambu Lab LAN send via FTPS + MQTT (community LAN protocol)."""
from __future__ import annotations

import json
import ssl
import time
from ftplib import FTP_TLS
from pathlib import Path

import paho.mqtt.client as mqtt

from .config import settings
from .models import PrinterStatus


def printer_configured(
    ip: str | None = None,
    access_code: str | None = None,
    serial: str | None = None,
) -> bool:
    ip = ip or settings.bambu_ip
    access_code = access_code or settings.bambu_access_code
    serial = serial or settings.bambu_serial
    return bool(ip and access_code and serial)


def get_printer_status() -> PrinterStatus:
    configured = printer_configured()
    if not configured:
        return PrinterStatus(
            configured=False,
            detail="Set BAMBU_IP, BAMBU_ACCESS_CODE, and BAMBU_SERIAL in the environment.",
        )
    return PrinterStatus(
        configured=True,
        ip=settings.bambu_ip,
        serial=settings.bambu_serial,
        reachable=None,
        detail="Credentials present. Reachability is checked when sending a job.",
    )


def _ftp_upload(ip: str, access_code: str, local_path: Path, remote_name: str) -> None:
    """Upload .gcode.3mf to printer SD/cache over FTPS."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    ftps = FTP_TLS(context=ctx)
    ftps.connect(ip, 990, timeout=30)
    ftps.auth()
    ftps.prot_p()
    ftps.login("bblp", access_code)
    # Prefer cache folder used by LAN prints
    for folder in ("/cache", "/"):
        try:
            ftps.cwd(folder)
            break
        except Exception:
            continue
    with local_path.open("rb") as fh:
        ftps.storbinary(f"STOR {remote_name}", fh)
    ftps.quit()


def _mqtt_start_print(ip: str, access_code: str, serial: str, remote_name: str) -> None:
    """Publish project_file print command over LAN MQTT (port 8883)."""
    topic = f"device/{serial}/request"
    payload = {
        "print": {
            "sequence_id": "0",
            "command": "project_file",
            "param": "Metadata/plate_1.gcode",
            "project_id": "0",
            "profile_id": "0",
            "task_id": "0",
            "subtask_id": "0",
            "subtask_name": remote_name,
            "file": remote_name,
            "url": f"ftp://bblp:@{ip}:990/cache/{remote_name}",
            "md5": "",
            "timelapse": False,
            "bed_type": "textured_plate",
            "bed_levelling": True,
            "flow_cali": True,
            "vibration_cali": True,
            "layer_inspect": False,
            "use_ams": False,
        }
    }

    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=f"lid-webapp-{int(time.time())}")
    client.username_pw_set("bblp", access_code)
    client.tls_set(cert_reqs=ssl.CERT_NONE)
    client.tls_insecure_set(True)

    err: list[str] = []

    def on_connect(client, userdata, flags, reason_code, properties=None):
        if reason_code != 0 and str(reason_code) not in ("Success", "0"):
            err.append(f"MQTT connect failed: {reason_code}")

    client.on_connect = on_connect
    client.connect(ip, settings.bambu_mqtt_port, keepalive=60)
    client.loop_start()
    time.sleep(1.0)
    result = client.publish(topic, json.dumps(payload), qos=1)
    result.wait_for_publish(timeout=15)
    time.sleep(0.5)
    client.loop_stop()
    client.disconnect()
    if err:
        raise RuntimeError("; ".join(err))
    if result.rc != mqtt.MQTT_ERR_SUCCESS:
        raise RuntimeError(f"MQTT publish failed rc={result.rc}")


def send_to_printer(
    gcode_3mf: Path,
    ip: str | None = None,
    access_code: str | None = None,
    serial: str | None = None,
) -> str:
    ip = ip or settings.bambu_ip
    access_code = access_code or settings.bambu_access_code
    serial = serial or settings.bambu_serial
    if not printer_configured(ip, access_code, serial):
        raise RuntimeError(
            "Printer not configured. Set BAMBU_IP, BAMBU_ACCESS_CODE, BAMBU_SERIAL "
            "or pass them in the print request. You can still download the .gcode.3mf."
        )
    if not gcode_3mf.exists():
        raise FileNotFoundError(str(gcode_3mf))

    remote_name = gcode_3mf.name
    if not remote_name.endswith(".gcode.3mf"):
        remote_name = remote_name.replace(".3mf", ".gcode.3mf")
        if not remote_name.endswith(".gcode.3mf"):
            remote_name += ".gcode.3mf"

    _ftp_upload(ip, access_code, gcode_3mf, remote_name)
    _mqtt_start_print(ip, access_code, serial, remote_name)
    return f"Uploaded {remote_name} to {ip} and sent print start for {serial}."
