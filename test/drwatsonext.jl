cd(@__DIR__)
path = "test_project"

initialize_project(path; force = true)
cd(path)
quickactivate(path)

@test cohortsdir() == abspath("data", "cohorts")
@test cohortsdir("under_review") == abspath("data", "cohorts", "under_review")
@test cohortsdir("under_review", "stroke.json") == abspath("data", "cohorts", "under_review", "stroke.json")

cd("..")
rm("test_project", recursive=true, force=true)
