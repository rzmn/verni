package defaultServer

import (
	"encoding/json"
	"net/http"
)

type Config struct {
	WebCredentials WebCredentials `json:"webcredentials"`
	AppClips       AppClips       `json:"appclips"`
	AppLinks       AppLinks       `json:"applinks"`
}

type WebCredentials struct {
	Apps []string `json:"apps"`
}

type AppClips struct{}

type AppLinks struct {
	Details []AppLinksDetails `json:"details"`
}

type AppLinksDetails struct {
	AppId string   `json:"appID"`
	Paths []string `json:"paths"`
}

const AppIdentifier = "NPZKGHFT2A.com.rzmn.dev.verni"

func aasaHandler(w http.ResponseWriter, r *http.Request) {
	var config = Config{
		WebCredentials: WebCredentials{
			Apps: []string{AppIdentifier},
		},
		AppClips: AppClips{},
		AppLinks: AppLinks{
			Details: []AppLinksDetails{
				{
					AppId: AppIdentifier,
					Paths: []string{"*"},
				},
			},
		},
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(config)
}
