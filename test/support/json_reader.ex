defmodule Typeid.Test.JSONReader do
  @folder Path.dirname(__ENV__.file)

  def invalid_cases() do
    File.read!("#{@folder}/typeid/spec/invalid.json") |> Jason.decode!()
  end

  def valid_cases() do
    File.read!("#{@folder}/typeid/spec/valid.json") |> Jason.decode!()
  end
end
