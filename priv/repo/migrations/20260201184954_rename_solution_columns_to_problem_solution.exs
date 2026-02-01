defmodule Reposit.Repo.Migrations.RenameSolutionColumnsToProblemSolution do
  use Ecto.Migration

  def change do
    rename table(:solutions), :problem_description, to: :problem
    rename table(:solutions), :solution_pattern, to: :solution
  end
end
