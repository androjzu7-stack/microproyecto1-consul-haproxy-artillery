# Artillery tests (Microproyecto 1)

Estos scripts generan tráfico hacia el **balanceador HAProxy** (host: `http://localhost:8080`) para caracterizar el comportamiento del sistema en diferentes escenarios.

## Archivos

- `baseline.yml`: carga suave y constante (línea base).
- `spike.yml`: pico fuerte de tráfico por pocos segundos (estrés).
- `soak.yml`: carga sostenida por más tiempo (estabilidad).

## Cómo ejecutar (desde el host)

Desde la raíz del proyecto:

```bash
artillery run tests/baseline.yml | tee tests/results-baseline.txt
artillery run tests/spike.yml    | tee tests/results-spike.txt
artillery run tests/soak.yml     | tee tests/results-soak.txt