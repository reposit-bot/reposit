defmodule Reposit.Accounts.DeviceCode do
  @moduledoc """
  Schema for device authorization flow.

  Device codes allow CLI/MCP tools to authenticate without direct browser access.
  The flow is:
  1. Client requests a device code
  2. User visits verification URL and enters the user_code
  3. User logs in and approves
  4. Client polls until approved, then receives API token
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Reposit.Accounts.{DeviceCode, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @hash_algorithm :sha256
  @rand_size 32
  @user_code_length 8
  @validity_in_minutes 15

  schema "device_codes" do
    field :device_code, :binary
    field :user_code, :string
    field :backend_url, :string
    field :expires_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @doc """
  Generates a new device code for the given backend URL.

  Returns `{device_code_string, user_code_string, %DeviceCode{}}`.
  The device_code_string should be returned to the client for polling.
  The user_code_string should be displayed to the user.
  """
  def build(backend_url) do
    # Generate a cryptographically secure device code
    device_code_raw = :crypto.strong_rand_bytes(@rand_size)
    device_code_hash = :crypto.hash(@hash_algorithm, device_code_raw)
    device_code_string = Base.url_encode64(device_code_raw, padding: false)

    # Generate a human-friendly user code (e.g., "ABCD-1234")
    user_code = generate_user_code()

    expires_at =
      DateTime.utc_now()
      |> DateTime.add(@validity_in_minutes, :minute)
      |> DateTime.truncate(:second)

    device_code = %DeviceCode{
      device_code: device_code_hash,
      user_code: user_code,
      backend_url: backend_url,
      expires_at: expires_at,
      user_id: nil
    }

    {device_code_string, user_code, device_code}
  end

  @doc """
  Verifies a device code and returns the query for the matching record.

  Returns `{:ok, query}` or `:error` if the code is invalid.
  """
  def verify_device_code_query(device_code_string) do
    case Base.url_decode64(device_code_string, padding: false) do
      {:ok, decoded} ->
        hashed = :crypto.hash(@hash_algorithm, decoded)

        query =
          from(dc in DeviceCode,
            where: dc.device_code == ^hashed,
            where: dc.expires_at > ^DateTime.utc_now()
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Finds a device code by user code (case-insensitive).
  """
  def by_user_code_query(user_code) do
    normalized = user_code |> String.upcase() |> String.replace("-", "")

    from(dc in DeviceCode,
      where: fragment("UPPER(REPLACE(?, '-', '')) = ?", dc.user_code, ^normalized),
      where: dc.expires_at > ^DateTime.utc_now(),
      where: is_nil(dc.user_id)
    )
  end

  @doc """
  Changeset for approving a device code (linking it to a user).
  """
  def approve_changeset(%DeviceCode{} = device_code, %User{} = user) do
    device_code
    |> change()
    |> put_change(:user_id, user.id)
  end

  @doc """
  Returns the validity period in minutes.
  """
  def validity_in_minutes, do: @validity_in_minutes

  # Generate a user-friendly code like "ABCD-1234"
  defp generate_user_code do
    # Use only uppercase letters and digits, avoiding confusing characters (0, O, I, 1, L)
    alphabet = ~c"ABCDEFGHJKMNPQRSTUVWXYZ23456789"
    len = length(alphabet)

    code =
      1..@user_code_length
      |> Enum.map(fn _ ->
        idx = :rand.uniform(len) - 1
        Enum.at(alphabet, idx)
      end)
      |> List.to_string()

    # Format as XXXX-XXXX
    String.slice(code, 0, 4) <> "-" <> String.slice(code, 4, 4)
  end
end
