# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
# FIX: Swapped out the unstable 'comfy node install' for direct Git cloning for LanPaint
RUN git clone https://github.com/scraed/LanPaint.git /comfyui/custom_nodes/LanPaint
RUN if [ -f /comfyui/custom_nodes/LanPaint/requirements.txt ]; then pip install --no-cache-dir -r /comfyui/custom_nodes/LanPaint/requirements.txt; fi

RUN git clone https://github.com/chrisgoringe/cg-use-everywhere /comfyui/custom_nodes/cg-use-everywhere && cd /comfyui/custom_nodes/cg-use-everywhere && (git checkout f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 2>/dev/null || (git fetch origin f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 --depth=1 && git checkout f72d23a7060db657a2775c4dd1f1a85a3efcf5a8) || echo "WARN: commit f72d23a7060db657a2775c4dd1f1a85a3efcf5a8 unreachable in https://github.com/chrisgoringe/cg-use-everywhere")
RUN comfy node install --exit-on-fail comfyui-inpaint-nodes@1.3.1 --mode remote || (echo "WARN: comfyui-inpaint-nodes@1.3.1 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-inpaint-nodes --mode remote)
RUN git clone https://github.com/cubiq/ComfyUI_essentials /comfyui/custom_nodes/ComfyUI_essentials && cd /comfyui/custom_nodes/ComfyUI_essentials && (git checkout a79590cc3295c207fb08bca0df8276f8e5306912 2>/dev/null || (git fetch origin a79590cc3295c207fb08bca0df8276f8e5306912 --depth=1 && git checkout a79590cc3295c207fb08bca0df8276f8e5306912) || echo "WARN: commit a79590cc3295c207fb08bca0df8276f8e5306912 unreachable in https://github.com/cubiq/ComfyUI_essentials")
RUN comfy node install --exit-on-fail comfyui-gimpal-llm@1.1.2 --mode remote || (echo "WARN: comfyui-gimpal-llm@1.1.2 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-gimpal-llm --mode remote)

# download models into comfyui
# exponential backoff is used to retry downloads up to 5 times if they fail.
# to use a huggingface token, pass --token $HF_TOKEN to the comfy model download command.
RUN BACKOFFS="1 2 4 8 16"; for i in $(seq 1 5); do comfy model download --url 'https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/flux2-vae.safetensors' --relative-path models/vae --filename 'flux2-vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="1 2 4 8 16"; for i in $(seq 1 5); do comfy model download --url 'https://huggingface.co/Kijai/flux-fp8/resolve/main/flux-2-klein-4b-bf16.safetensors' --relative-path models/unet --filename 'flux-2-klein-4b-bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="1 2 4 8 16"; for i in $(seq 1 5); do comfy model download --url 'https://huggingface.co/Comfy-Org/Qwen2.5-3B-Instruct_gemma-4-text-encoder-scaled-fp8/resolve/main/qwen3_4b_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'qwen3_4b_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="1 2 4 8 16"; for i in $(seq 1 5); do comfy model download --url 'https://huggingface.co/Comfy-Org/gemma-4/resolve/main/text_encoders/gemma4_e4b_it_fp8_scaled.safetensors' --relative-path models/text_encoders --filename 'gemma4_e4b_it_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# user-provided inputs override the auto-generated placeholders above.
RUN wget --progress=dot:giga -O '/comfyui/input/pexels-peterfazekas-1137340.jpg' "https://cool-anteater-319.convex.cloud/api/storage/ba74cdaf-7dd2-45f1-a732-8a95aa4fccec"
RUN wget --progress=dot:giga -O '/comfyui/input/indian_ethnic_wear_male1.webp' "https://cool-anteater-319.convex.cloud/api/storage/4f0e6345-c48e-4adc-b2b8-efdf46ea18cf"
