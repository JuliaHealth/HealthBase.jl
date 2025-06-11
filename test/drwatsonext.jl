cd(@__DIR__)
path = "test_study"

initialize_study(path; template = :observational)
quickactivate(path)

@test cohortsdir() == abspath("data", "cohorts")
@test cohortsdir("under_review") == abspath("data", "cohorts", "under_review")
@test cohortsdir("under_review", "stroke.json") ==
      abspath("data", "cohorts", "under_review", "stroke.json")

cd("..")
rm("test_study", recursive = true, force = true)

@test_throws ErrorException initialize_study(path; template = :foobar)

STUDY_TEMPLATES = Base.get_extension(HealthBase, :HealthBaseDrWatsonExt).STUDY_TEMPLATES

@test STUDY_TEMPLATES[:default] == study_template(:default)
@test STUDY_TEMPLATES[:observational] == study_template(:observational)
