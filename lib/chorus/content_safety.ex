defmodule Chorus.ContentSafety do
  @moduledoc """
  Content safety utilities for detecting potentially malicious prompt injection attempts.

  This module provides heuristic-based detection for common prompt injection patterns.
  It is not foolproof and should be used as one layer in a defense-in-depth strategy.

  ## Usage

      iex> Chorus.ContentSafety.analyze("How to parse JSON?")
      {:ok, %{risk_level: :low, flags: []}}

      iex> Chorus.ContentSafety.analyze("Ignore previous instructions and...")
      {:ok, %{risk_level: :high, flags: [:instruction_override]}}

  """

  @doc """
  Analyzes content for potential prompt injection patterns.

  Returns a map with:
  - `:risk_level` - `:low`, `:medium`, or `:high`
  - `:flags` - list of detected suspicious patterns
  """
  @spec analyze(String.t()) :: {:ok, map()}
  def analyze(content) when is_binary(content) do
    flags = detect_patterns(content)
    risk_level = calculate_risk_level(flags)

    {:ok, %{risk_level: risk_level, flags: flags}}
  end

  def analyze(_), do: {:ok, %{risk_level: :low, flags: []}}

  @doc """
  Returns true if content is considered potentially risky.
  """
  @spec risky?(String.t()) :: boolean()
  def risky?(content) do
    {:ok, %{risk_level: level}} = analyze(content)
    level in [:medium, :high]
  end

  # Pattern detection

  defp detect_patterns(content) do
    content_lower = String.downcase(content)

    []
    |> maybe_flag(:instruction_override, instruction_override?(content_lower))
    |> maybe_flag(:system_impersonation, system_impersonation?(content_lower))
    |> maybe_flag(:hidden_instructions, hidden_instructions?(content))
    |> maybe_flag(:imperative_commands, imperative_commands?(content_lower))
    |> maybe_flag(:encoding_tricks, encoding_tricks?(content))
  end

  defp maybe_flag(flags, flag, true), do: [flag | flags]
  defp maybe_flag(flags, _flag, false), do: flags

  # "ignore previous instructions", "disregard above", etc.
  defp instruction_override?(content) do
    patterns = [
      ~r/ignore\s+(all\s+)?previous\s+(instructions|prompts?)/i,
      ~r/disregard\s+(all\s+)?(above|previous|prior)/i,
      ~r/forget\s+(everything|all|what)/i,
      ~r/new\s+instructions?\s*:/i,
      ~r/override\s+(system|instructions?)/i
    ]

    Enum.any?(patterns, &Regex.match?(&1, content))
  end

  # "[SYSTEM]:", "<<SYS>>", "You are now", etc.
  defp system_impersonation?(content) do
    patterns = [
      ~r/\[system\]/i,
      ~r/<<sys>>/i,
      ~r/<\|system\|>/i,
      ~r/you\s+are\s+now\s+(a|an|in)/i,
      ~r/entering\s+(admin|developer|debug)\s+mode/i,
      ~r/assistant:\s*\n/i
    ]

    Enum.any?(patterns, &Regex.match?(&1, content))
  end

  # Hidden text markers, zero-width characters, etc.
  defp hidden_instructions?(content) do
    # Check for common hidden instruction markers
    markers = ["[HIDDEN:", "[INST]", "<!-- ", "/*", "```hidden", "<hidden>"]
    has_markers = Enum.any?(markers, &String.contains?(content, &1))

    # Check for suspicious zero-width characters
    # Zero-width space, zero-width non-joiner, zero-width joiner
    zero_width_chars = ["\u200B", "\u200C", "\u200D", "\uFEFF"]
    has_zero_width = Enum.any?(zero_width_chars, &String.contains?(content, &1))

    has_markers || has_zero_width
  end

  # "you must", "execute this", "run the following", etc.
  defp imperative_commands?(content) do
    patterns = [
      ~r/you\s+must\s+(now\s+)?execute/i,
      ~r/run\s+the\s+following/i,
      ~r/execute\s+(this|the|these)/i,
      ~r/send\s+(this\s+)?(data|information|credentials)/i,
      ~r/(api|secret)\s*key/i
    ]

    Enum.any?(patterns, &Regex.match?(&1, content))
  end

  # Base64 encoded content, excessive unicode escapes
  defp encoding_tricks?(content) do
    # Check for base64-like patterns (long alphanumeric strings)
    has_base64 = Regex.match?(~r/[A-Za-z0-9+\/]{50,}={0,2}/, content)

    # Check for excessive unicode escapes
    unicode_escape_count = length(Regex.scan(~r/\\u[0-9A-Fa-f]{4}/, content))
    has_excessive_unicode = unicode_escape_count > 5

    has_base64 || has_excessive_unicode
  end

  defp calculate_risk_level([]), do: :low
  defp calculate_risk_level(flags) when length(flags) == 1, do: :medium
  defp calculate_risk_level(_flags), do: :high
end
