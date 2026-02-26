# Microproyecto 1 — Consul + HAProxy + Artillery (Vagrant)

## Topología
- **lb**: 192.168.100.10 (Consul + HAProxy + Consul Template)
- **web1**: 192.168.100.11 (Consul + NodeJS multi-instancia)
- **web2**: 192.168.100.12 (Consul + NodeJS multi-instancia)
- **client**: 192.168.100.13 (Artillery)

## Accesos desde el host
- Servicio (HAProxy): http://192.168.100.10/
- HAProxy Stats: http://192.168.100.10:1936/
- Consul UI: http://192.168.100.10:8500/

## Ejecución
```bash
vagrant up
vagrant provision

# Validación de Consul (cluster y discovery)
vagrant ssh lb -c "consul members"
vagrant ssh lb -c "dig +short SRV _web._tcp.service.consul @127.0.0.1 -p 8600"

# Balanceo (8 instancias)
for i in {1..40}; do curl -s http://192.168.100.10 | jq -r '.node+":" + (.port|tostring)'; done | sort | uniq -c

# Caso sin servidores (503 personalizado)
vagrant ssh web1 -c "sudo systemctl stop --all 'web@*' && sudo consul reload"
vagrant ssh web2 -c "sudo systemctl stop --all 'web@*' && sudo consul reload"
- abrir http://192.168.100.10/ (debe mostrar 503 personalizado)

# Pruebas de carga (Artillery desde client)
vagrant ssh client -c "artillery run ~/tests/baseline.yml"
vagrant ssh client -c "artillery run ~/tests/spike.yml"
vagrant ssh client -c "artillery run ~/tests/soak.yml"

# Extra — Cliente visible en frontend
vagrant ssh lb -c "echo 'show table http_front' | sudo socat stdio /run/haproxy/admin.sock"

#Evidencias
Documento: Microproyecto1_Entrega_Final.docx
Scripts: scripts/ (common.sh, consul.sh, web.sh, lb.sh, client.sh)
Pruebas: tests/ (baseline.yml, spike.yml, soak.yml + resultados)