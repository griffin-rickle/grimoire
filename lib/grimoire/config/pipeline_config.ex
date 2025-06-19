defmodule Grimoire.Config.PipelineConfig do
  defstruct [:csv_path, :batch_size]

  def load(:musicbrainz) do
    config = Application.get_env(:grimoire, Grimoire.Pipelines.Musicbrainz)
    %__MODULE__{
      csv_path: config[:csv_path],
      batch_size: config[:batch_size]
    }
  end
end
