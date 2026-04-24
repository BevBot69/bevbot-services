# Ollama on Bevbot 2.0 — VRAM Guide

## RTX PRO 500 Blackwell — Specs

The RTX PRO 500 is a Blackwell-generation laptop GPU. Exact VRAM depends on your specific SKU — verify with:

```bash
nvidia-smi --query-gpu=name,memory.total --format=csv
```

Typical configurations for the PRO 500 series range from **8 GB to 16 GB GDDR7**.

---

## Model VRAM Requirements

| Model | VRAM Required | Notes |
|---|---|---|
| llama3.2:3b | ~2 GB | Fastest, good for quick tasks |
| llama3.2:8b | ~5 GB | Good balance of speed/quality |
| llama3.1:8b | ~5 GB | Strong general model |
| mistral:7b | ~5 GB | Fast, good reasoning |
| llama3.1:70b | ~40 GB | Too large — use CPU offload or skip |
| qwen2.5:7b | ~5 GB | Good for code |
| qwen2.5:14b | ~9 GB | Excellent if you have 12 GB+ VRAM |
| deepseek-r1:8b | ~5 GB | Good reasoning model |
| nomic-embed-text | ~0.5 GB | Embeddings (for RAG) |

## Recommendations for RTX PRO 500

**If you have 8 GB VRAM:** Stick to 7B–8B parameter models. Multiple models can be loaded but will compete for VRAM.

**If you have 12–16 GB VRAM:** You can run 14B models comfortably. 32B models may partially fit with CPU offload (`OLLAMA_GPU_OVERHEAD` setting).

## Deploying Ollama

```bash
# Deploy (ad-hoc — only when you want it)
ansible-playbook ansible/playbooks/bevbot2.yml --tags ollama --ask-vault-pass

# Pull a model after deployment (from bevbot2 or via Tailscale)
podman exec -it ollama ollama pull llama3.2:8b

# Check what's loaded
podman exec -it ollama ollama list

# Run interactively
podman exec -it ollama ollama run llama3.2:8b

# Check GPU utilization while running
nvidia-smi dmon -s u
```

## Stopping Ollama (to free VRAM for gaming)

```bash
# On bevbot2
systemctl --user stop ollama

# Or via Ansible
ansible bevbot2_group -m systemd -a "name=ollama state=stopped scope=user" \
  --become --become-user your_username
```

## Resource Usage Considerations

Ollama will hold models in VRAM until evicted. If you're gaming and Jellyfin transcoding simultaneously, you may want to:

1. Stop Ollama before gaming sessions
2. Or set `OLLAMA_MAX_LOADED_MODELS=1` to limit memory usage
3. Or run Ollama CPU-only (`ollama_gpu_enabled: false`) for background use

CPU inference on the Ultra 7 265H is still usable for smaller models (~2–4 tokens/sec for 8B).
