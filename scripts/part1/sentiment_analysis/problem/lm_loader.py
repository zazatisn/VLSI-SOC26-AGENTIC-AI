import os
import yaml
import dspy

def load_configured_lm(config_path="config.yaml") -> dspy.LM:
    """Loads LM settings from YAML and initializes dspy.LM."""
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file '{config_path}' not found.")

    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)

    active_profile = config.get("active_profile")
    profiles = config.get("profiles", {})

    if active_profile not in profiles:
        raise ValueError(f"Profile '{active_profile}' is not defined in {config_path}")

    # Copy arguments for active profile
    lm_kwargs = profiles[active_profile].copy()

    # Resolve API Key from environment if user passed an ENV variable name (e.g., "$GROQ_API_KEY")
    api_key = lm_kwargs.get("api_key", "")
    if isinstance(api_key, str) and api_key.startswith("$"):
        env_var_name = api_key[1:]
        lm_kwargs["api_key"] = os.getenv(env_var_name, "")

    # Clean up empty optional fields
    if not lm_kwargs.get("api_key"):
        lm_kwargs.pop("api_key", None)
    if not lm_kwargs.get("api_base"):
        lm_kwargs.pop("api_base", None)

    print(f"--> Initializing DSPy LM profile: '{active_profile}' ({lm_kwargs.get('model')})")
    
    # DSPy automatically handles model routing via kwargs
    return dspy.LM(**lm_kwargs)