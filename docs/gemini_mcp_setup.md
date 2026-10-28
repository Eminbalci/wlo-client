# Global Gemini Multi-Account MCP Server Specification

## 1. Overview
The Gemini MCP server integrates Google Gemini models across multiple Google AI Studio accounts with automated quota fallback, model routing, and error recovery. It is globally configured for both Claude Code (`~/.claude.json` user scope) and Claude Desktop (`%APPDATA%\Claude\claude_desktop_config.json`).

## 2. Server Installation Details
- **Script Path**: `C:\Users\muham\tools\gemini-mcp\gemini_mcp.py`
- **Synced Desktop Copy**: `C:\Users\muham\Desktop\gemini_mcp.py`
- **Execution Engine**: `C:\Users\muham\AppData\Roaming\Python\Python314\Scripts\uv.exe run --script C:\Users\muham\tools\gemini-mcp\gemini_mcp.py`
- **Dependencies (PEP 723)**:
  - `mcp>=1.2,<2` (pinned to maintain FastMCP API stability against MCP 2.x breaking changes)
  - `google-genai>=1.0`

## 3. Environment Variables & Account Rotation
| Environment Variable | Description | Default |
|---|---|---|
| `GEMINI_KEY_<ACCOUNT>` | API key for account `<ACCOUNT>` (e.g. `GEMINI_KEY_HESAP1`..`HESAP6`) | Extracted from `google api.txt` |
| `GEMINI_DEFAULT` | Name of the primary account to attempt first | `hesap1` |
| `GEMINI_MODEL` | Default Gemini model identifier | `gemini-3.1-flash-lite` |
| `GEMINI_FALLBACK` | Toggle ("1" or "0") automatic failover to remaining accounts on quota exhaustion / rate limiting | `1` (enabled) |
| `MCP_TRANSPORT` | Transport mechanism (`stdio` or `streamable-http`) | `stdio` |

## 4. MCP Tools Specification

### 4.1. `list_accounts`
- **Description**: Returns all registered accounts with masked keys, current default account, active model, and fallback status.
- **Parameters**: None.
- **Return Type**: `str`
- **Exceptions**: None. Returns `"Hiç hesap tanımlı değil."` if no accounts are present in environment.

### 4.2. `ask_gemini`
- **Description**: Sends a prompt to the specified or default Gemini model with automatic account failover on rate limits (429), high demand / server overload (503), or quota exhaustion.
- **Parameters**:
  - `prompt` (`str`, required): User or system prompt text.
  - `account` (`str | None`, optional): Force a specific account name. Disables fallback if specified.
  - `model` (`str | None`, optional): Model name (e.g., `gemini-3.1-flash-lite`, `gemini-3.8-flash`, `gemini-2.5-pro`). Defaults to `DEFAULT_MODEL`.
  - `system_instruction` (`str | None`, optional): System prompt configuration.
  - `temperature` (`float | None`, optional): Sampling temperature.
  - `max_output_tokens` (`int | None`, optional): Output token budget limit.
- **Return Type**: `str` (Contains response text followed by attribution tag `[hesap: <name>, model: <model>]` and any logged failovers).
- **Exceptions & Error Handling**:
  - Catches `google.genai.errors.APIError` and standard exceptions.
  - If error code is `429`, `500`, `502`, `503`, `504` or message contains `RESOURCE_EXHAUSTED`, `UNAVAILABLE`, `HIGH DEMAND`, `OVERLOADED`, automatically tries subsequent registered accounts.
  - If all accounts fail or an unretryable error occurs (e.g. 400 Bad Request), returns diagnostic log string starting with `"Gemini isteği başarısız oldu:"`.

### 4.3. `list_models`
- **Description**: Lists all text-generation supported models accessible by the designated account.
- **Parameters**:
  - `account` (`str | None`, optional): Target account to query. Defaults to `DEFAULT_ACCOUNT`.
- **Return Type**: `str` (Formatted newline-delimited model list).
- **Exceptions**: Raises `ValueError` if specified account name does not exist.

## 5. Verification
- Handshake: JSON-RPC 2.0 initialize returned protocol version `2024-11-05`, server `gemini` v1.30.0.
- Health Check: `claude mcp list` reported `✔ Connected` across all projects.
- Query Check: Verified real generation with prompt response `MCP OK` and valid account attribution.
