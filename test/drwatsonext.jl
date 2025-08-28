cd(@__DIR__)

github_name = "foo"
path = "test_study"

@test_warn "" initialize_study(path; template = :llm);

cd("..")
rm("test_study", recursive = true, force = true)

mktemp() do fname, f
    write(f, "X")
    seek(f, 0)
    redirect_stdin(f) do
        @test initialize_study(path; template = :llm) == nothing
    end
end

cd("..")
rm("test_study", recursive = true, force = true)

initialize_study(path; github_name = github_name, template = :observational)
quickactivate(path)

@test cohortsdir() == abspath("data", "cohorts")
@test cohortsdir("under_review") == abspath("data", "cohorts", "under_review")
@test cohortsdir("under_review", "stroke.json") ==
      abspath("data", "cohorts", "under_review", "stroke.json")

cd("..")
rm("test_study", recursive = true, force = true)

initialize_study(path; github_name = github_name, template = :llm)
quickactivate(path)

@test corpusdir() == abspath("data", "corpus")
@test corpusdir("sample") == abspath("data", "corpus", "sample")
@test corpusdir("sample", "text.txt") == abspath("data", "corpus", "sample", "text.txt")

@test modelsdir() == abspath("data", "models")
@test modelsdir("model.gguf") == abspath("data", "models", "model.gguf")

@test configdir() == abspath("data", "config")
@test configdir("sample.modelfile") == abspath("data", "config", "sample.modelfile")

cd("..")
rm("test_study", recursive = true, force = true)

@test_throws ErrorException initialize_study(
    path;
    github_name = github_name,
    template = :foobar,
)

STUDY_TEMPLATES = Base.get_extension(HealthBase, :HealthBaseDrWatsonExt).STUDY_TEMPLATES

@test STUDY_TEMPLATES[:default] == study_template(:default)
@test STUDY_TEMPLATES[:observational] == study_template(:observational)
@test STUDY_TEMPLATES[:llm] == study_template(:llm)
