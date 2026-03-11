# Networking Guide

This guide covers all networking capabilities in **amitOS**, including Netplan configuration, Nginx reverse proxy, TLS certificate management, firewall rules, and VLAN setup.

---

## Netplan Configuration

amitOS uses **Netplan** for declarative network configuration. All config files live in `/etc/netplan/`.

### DHCP (Automatic IP)

```yaml
# /etc/netplan/01-amitos.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
```

### Static IP

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

### Multiple Interfaces

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:                        # OT (Operational Technology) network
      dhcp4: no
      addresses: [192.168.10.1/24]
    eth1:                        # IT / Internet network
      dhcp4: yes
```

### Apply Changes

```bash
# Validate config (reverts if broken)
sudo netplan try

# Apply immediately
sudo netplan apply

# Debug connectivity
sudo netplan --debug apply
```

---

## Nginx Reverse Proxy

amitOS includes **Nginx** pre-configured as a reverse proxy for internal services.

### Default Configuration Location

```
/etc/nginx/
├── nginx.conf              # Main config
├── sites-available/        # Available site configs
│   └── amitos-dashboard    # Web dashboard (when available)
└── sites-enabled/          # Symlinks to enabled sites
```

### Example: Proxy Internal Service

```nginx
# /etc/nginx/sites-available/my-service
server {
    listen 443 ssl;
    server_name amitos.local;

    ssl_certificate     /etc/amitos/tls/amitos.crt;
    ssl_certificate_key /etc/amitos/tls/amitos.key;

    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        root /var/www/amitos;
        try_files $uri $uri/ =404;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/my-service /etc/nginx/sites-enabled/
sudo nginx -t        # Test config
sudo systemctl reload nginx
```

---

## TLS Certificate Management

### Generate a Self-Signed Certificate (Development)

```bash
sudo mkdir -p /etc/amitos/tls
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/amitos/tls/amitos.key \
  -out /etc/amitos/tls/amitos.crt \
  -subj "/C=IN/ST=State/L=City/O=amitOS/CN=amitos.local"
```

### Using Let's Encrypt (Production, Public Domain)

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
sudo certbot renew --dry-run
```

### OPC UA TLS Configuration

OPC UA security requires a dedicated certificate:

```bash
# Generate OPC UA server certificate
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/amitos/opcua/server.key \
  -out /etc/amitos/opcua/server.crt
```

---

## Firewall (nftables)

amitOS uses **nftables** for stateful packet filtering. A default ruleset is applied during installation.

### View Current Rules

```bash
sudo nft list ruleset
```

### Common Operations

```bash
# Allow OPC UA port (4840)
sudo nft add rule inet filter input tcp dport 4840 accept

# Allow MQTT port (1883) from specific subnet
sudo nft add rule inet filter input ip saddr 192.168.1.0/24 tcp dport 1883 accept

# Allow HTTPS
sudo nft add rule inet filter input tcp dport 443 accept

# Block an IP
sudo nft add rule inet filter input ip saddr 10.0.0.5 drop

# Save rules (persist across reboots)
sudo nft list ruleset > /etc/nftables.conf
sudo systemctl enable nftables
```

### Default Allowed Ports

| Port | Protocol | Service |
|---|---|---|
| 22 | TCP | SSH |
| 80 | TCP | HTTP (redirect to HTTPS) |
| 443 | TCP | HTTPS / Nginx |
| 1883 | TCP | MQTT |
| 4840 | TCP | OPC UA |
| 47808 | UDP | BACnet/IP |

---

## VLAN Configuration

VLANs can be configured via Netplan to segment OT and IT networks:

```yaml
# /etc/netplan/01-amitos.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
  vlans:
    vlan10:             # OT network (PLC/SCADA)
      id: 10
      link: eth0
      addresses: [192.168.10.1/24]
    vlan20:             # IT network (servers)
      id: 20
      link: eth0
      addresses: [192.168.20.1/24]
```

```bash
sudo netplan apply
ip link show  # Verify VLAN interfaces are up
```

---

## Troubleshooting

| Issue | Command | Notes |
|---|---|---|
| Netplan not applying | `sudo netplan --debug apply` | Shows config parse errors |
| Nginx config error | `sudo nginx -t` | Test before reload |
| Port not accessible | `sudo nft list ruleset` | Check firewall rules |
| VLAN not showing | `ip link show` | Verify interface is UP |
| DNS not resolving | `resolvectl status` | Check resolved config |
