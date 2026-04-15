defmodule GodvilleSk.Game.LogMetadata do
  @moduledoc """
  Модуль для валидации и нормализации metadata событий журнала.
  Обеспечивает строгую валидацию типов событий и контекстов.
  """

  # Допустимые контексты событий.
  @contexts [:normal, :sovngarde, :battle_keeper]

  # Допустимые типы событий.
  @event_types [
    "initiative_roll",
    "combat_roll",
    "skill_roll",
    "sovngarde_task",
    "sovngarde_thought",
    "death",
    "resurrection",
    "quest_event",
    "quest_started",
    "memory",
    "injury",
    "limb_loss"
  ]

  # Схемы валидации для каждого типа события.
  # Ключ - тип события, значение - список обязательных полей.
  @schemas %{
    "initiative_roll" => [:hero_roll, :enemy_roll, :turn],
    "combat_roll" => [:actor, :target, :roll, :total, :damage, :is_hit],
    "skill_roll" => [:action, :roll, :total, :success],
    "sovngarde_task" => [:task_id, :title],
    "sovngarde_thought" => [],
    "death" => [],
    "resurrection" => [],
    "quest_event" => [],
    "quest_started" => [],
    "memory" => [],
    "injury" => [],
    "limb_loss" => []
  }

  def validate(metadata, context \\ :normal)

  def validate(metadata, context) when is_map(metadata) do
    with {:ok, _} <- validate_context(context),
         {:ok, _} <- validate_event_type(metadata),
         {:ok, _} <- validate_schema(metadata) do
      {:ok, normalize_metadata(metadata, context)}
    else
      error -> error
    end
  end

  def validate(_metadata, _context), do: {:error, :invalid_metadata_format}

  @doc """
  Нормализует metadata, добавляя контекст и приводя типы данных.
  """
  def normalize_metadata(metadata, context) when is_map(metadata) do
    metadata
    |> Map.put(:context, context)
    |> normalize_types()
  end

  @doc """
  Проверяет, является ли контекст допустимым.
  """
  def valid_context?(context) when context in @contexts, do: true
  def valid_context?(_), do: false

  @doc """
  Проверяет, является ли тип события допустимым.
  """
  def valid_event_type?(type) when type in @event_types, do: true
  def valid_event_type?(_), do: false

  @doc """
  Возвращает список всех допустимых контекстов.
  """
  def contexts, do: @contexts

  @doc """
  Возвращает список всех допустимых типов событий.
  """
  def event_types, do: @event_types

  @doc """
  Возвращает схему валидации для указанного типа события.
  """
  def schema_for_type(type) when is_binary(type), do: Map.get(@schemas, type)
  def schema_for_type(_), do: nil

  defp validate_context(context) do
    if valid_context?(context) do
      {:ok, context}
    else
      {:error, {:invalid_context, context}}
    end
  end

  defp validate_event_type(metadata) do
    type = Map.get(metadata, :type)

    if is_nil(type) or valid_event_type?(type) do
      {:ok, type}
    else
      {:error, {:invalid_event_type, type}}
    end
  end

  defp validate_schema(metadata) do
    type = Map.get(metadata, :type)

    if is_nil(type) do
      {:ok, :no_type}
    else
      case schema_for_type(type) do
        nil ->
          {:error, {:unknown_schema, type}}

        required_fields ->
          validate_required_fields(metadata, required_fields, type)
      end
    end
  end

  defp validate_required_fields(metadata, required_fields, type) do
    missing_fields =
      Enum.filter(required_fields, fn field ->
        is_nil(Map.get(metadata, field))
      end)

    if Enum.empty?(missing_fields) do
      {:ok, type}
    else
      {:error, {:missing_fields, type, missing_fields}}
    end
  end

  defp normalize_types(metadata) do
    metadata
    |> normalize_atom_keys()
    |> normalize_boolean_values()
  end

  defp normalize_atom_keys(metadata) do
    Enum.reduce(metadata, %{}, fn
      {key, value}, acc when is_binary(key) ->
        Map.put(acc, String.to_existing_atom(key), value)

      {key, value}, acc when is_atom(key) ->
        Map.put(acc, key, value)
    end)
  rescue
    ArgumentError ->
      metadata
  end

  defp normalize_boolean_values(metadata) do
    Enum.reduce(metadata, %{}, fn
      {key, value}, acc when is_boolean(value) ->
        Map.put(acc, key, value)

      {key, "true"}, acc ->
        Map.put(acc, key, true)

      {key, "false"}, acc ->
        Map.put(acc, key, false)

      {key, value}, acc ->
        Map.put(acc, key, value)
    end)
  end
end
