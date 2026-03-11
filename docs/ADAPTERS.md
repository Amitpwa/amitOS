# Adapter Framework Guide

amitOS includes a **plug-and-play adapter framework** that bridges industrial fieldbuses and protocols to the application layer. This guide covers the built-in adapters and explains how to write a custom adapter.

---

## Overview

Each adapter is an independent, self-contained service that:

1. Connects to a device or broker using its native protocol
2. Normalizes device data into amitOS's internal message format
3. Publishes that data to the internal message bus (OPC UA / MQTT topics)
4. Subscribes to write-back commands from higher-level applications

```
Device (Modbus PLC)
        │  Modbus TCP/RTU
        ▼
   Modbus Adapter
        │  Internal Message Bus
        ▼
   OPC UA Server  ──►  SCADA / HMI / AI Engine
```

---

## Built-in Adapters

### 1. Modbus Adapter

| Property | Value |
|---|---|
| Config file | `/etc/amitos/adapters/modbus.yaml` |
| Service | `modbus-adapter.service` |
| Protocols | Modbus TCP, Modbus RTU |

**Example config:**

```yaml
modbus:
  mode: tcp           # tcp or rtu
  host: 192.168.1.50  # PLC IP (TCP mode)
  port: 502
  unit_id: 1
  poll_interval_ms: 500
  registers:
    - name: temperature
      address: 40001
      type: holding
    - name: pressure
      address: 40002
      type: holding
```

---

### 2. MQTT Adapter

| Property | Value |
|---|---|
| Config file | `/etc/amitos/adapters/mqtt.yaml` |
| Service | `mqtt-adapter.service` |
| Protocols | MQTT v3.1, MQTT v5 |

**Example config:**

```yaml
mqtt:
  broker: mqtt://192.168.1.10:1883
  client_id: amitos-mqtt-adapter
  username: amitos
  password: secret
  subscribe_topics:
    - factory/sensors/#
    - factory/alerts/#
  publish_topic: amitos/mqtt/out
  qos: 1
```

---

### 3. Siemens S7 Adapter

| Property | Value |
|---|---|
| Config file | `/etc/amitos/adapters/siemens-s7.yaml` |
| Service | `siemens-s7-adapter.service` |
| Protocols | S7 protocol (ISO-on-TCP) |

**Example config:**

```yaml
siemens_s7:
  host: 192.168.1.80
  rack: 0
  slot: 1
  poll_interval_ms: 1000
  data_blocks:
    - db: 1
      offset: 0
      size: 100
      name: production_data
```

---

### 4. BACnet Adapter

| Property | Value |
|---|---|
| Config file | `/etc/amitos/adapters/bacnet.yaml` |
| Service | `bacnet-adapter.service` |
| Protocols | BACnet/IP |

**Example config:**

```yaml
bacnet:
  local_ip: 192.168.1.100
  broadcast_ip: 192.168.1.255
  port: 47808
  device_id: 1001
  poll_interval_ms: 2000
  objects:
    - type: analog-input
      instance: 1
      name: room_temperature
    - type: binary-output
      instance: 2
      name: hvac_switch
```

---

### 5. REST API Bridge

| Property | Value |
|---|---|
| Config file | `/etc/amitos/adapters/rest-bridge.yaml` |
| Service | `rest-bridge-adapter.service` |
| Protocols | HTTP/HTTPS REST |

**Example config:**

```yaml
rest_bridge:
  endpoints:
    - name: sensor_api
      url: https://api.example.com/sensors
      method: GET
      poll_interval_sec: 10
      auth:
        type: bearer
        token: your-api-token
      data_path: "$.data.readings"
  outbound:
    url: https://api.example.com/commands
    method: POST
```

---

## Managing Adapters

```bash
# Start an adapter
sudo systemctl start modbus-adapter

# Enable adapter on boot
sudo systemctl enable modbus-adapter

# View adapter logs
journalctl -u modbus-adapter -f

# Restart all adapters
sudo systemctl restart modbus-adapter mqtt-adapter siemens-s7-adapter
```

---

## Writing a Custom Adapter

Custom adapters can be written in **Python** or **Bash** and registered as systemd services.

### Step 1: Create the Adapter Script

```python
# /opt/amitos/adapters/my_custom_adapter.py
import time
import yaml
import paho.mqtt.client as mqtt  # or any library you need

def load_config():
    with open("/etc/amitos/adapters/my_custom.yaml") as f:
        return yaml.safe_load(f)

def run():
    config = load_config()
    # Connect to your device here
    while True:
        # Read data from device
        data = {"temperature": 25.5, "status": "ok"}
        # Publish to internal OPC UA or MQTT bus
        print(f"Publishing: {data}")
        time.sleep(config.get("poll_interval_sec", 5))

if __name__ == "__main__":
    run()
```

### Step 2: Create the Config File

```yaml
# /etc/amitos/adapters/my_custom.yaml
poll_interval_sec: 5
device_ip: 192.168.1.200
```

### Step 3: Register as a systemd Service

```ini
# /etc/systemd/system/my-custom-adapter.service
[Unit]
Description=amitOS Custom Adapter
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/amitos/adapters/my_custom_adapter.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable my-custom-adapter
sudo systemctl start my-custom-adapter
```

---

## Adapter SDK *(coming soon)*

A formal **Adapter SDK** with a base class, standard message schemas, and testing utilities is planned for `v0.3.0`. See [ROADMAP.md](ROADMAP.md).
