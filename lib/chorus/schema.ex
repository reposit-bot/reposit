defmodule Chorus.Schema do
  @moduledoc """
  Shared schema configuration for Chorus.

  Provides consistent defaults for all Ecto schemas:
  - UUID primary keys
  - UUID foreign keys
  - Microsecond precision timestamps

  ## Usage

      defmodule Chorus.Solutions.Solution do
        use Chorus.Schema

        schema "solutions" do
          field :name, :string
          timestamps()
        end
      end

  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      alias Chorus.Repo

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]

      @type t :: %__MODULE__{}
    end
  end
end
