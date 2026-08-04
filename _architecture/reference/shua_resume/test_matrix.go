package main

import (
	"encoding/json"
	"fmt"
	"shua_resume/pkg/handlers"
	"shua_resume/pkg/models"
)

func main() {
	ctx := map[string]interface{}{}
	
	// Mock an empty DB result
	ctx["work_items"] = []models.WorkItem{}
	ctx["education_items"] = []models.Education{}
	ctx["project_items"] = []models.ProjectItem{}

	res, err := handlers.LoadAndHydrateBlueprint("resume_matrix", ctx)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	b, _ := json.MarshalIndent(res, "", "  ")
	fmt.Println(string(b))
}
