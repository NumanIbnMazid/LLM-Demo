from langchain_community.llms import LlamaCpp
from langchain_core.callbacks import CallbackManager, StreamingStdOutCallbackHandler
from langchain_core.prompts import PromptTemplate

# Installation guide (GPU): https://python.langchain.com/v0.1/docs/integrations/llms/llamacpp/

n_gpu_layers = -1  # The number of layers to put on the GPU. The rest will be on the CPU. If you don't know how many layers there are, you can use -1 to move all to GPU.
n_batch = 512  # Should be between 1 and n_ctx, consider the amount of VRAM in your GPU.

template = """Question: {question}

Answer: Let's work this out in a step by step way to be sure we have the right answer."""

prompt = PromptTemplate.from_template(template)

# Callbacks support token-wise streaming
callback_manager = CallbackManager([StreamingStdOutCallbackHandler()])

# model link: https://huggingface.co/TheBloke/Llama-2-7B-GGUF/tree/main

# Make sure the model path is correct for your system!
llm = LlamaCpp(
    model_path="/project/models/llama-2-7b.Q2_K.gguf",
    n_gpu_layers=n_gpu_layers,
    n_batch=n_batch,
    callback_manager=callback_manager,
    verbose=True,  # Verbose is required to pass to the callback manager
)

llm_chain = prompt | llm

question = "What is the difference between method overriding and method overloading?"
# llm_chain.invoke({"question": question})

# %%capture captured --no-stdout
result = llm_chain.invoke({"question": question})

print("Result: \n")
print(result)
