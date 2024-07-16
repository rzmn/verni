package main

import (
	"log"
	"net/http"

	"accounty/internal/config"
	"accounty/internal/http-server/router/auth"
	"accounty/internal/http-server/router/friends"
	"accounty/internal/http-server/router/users"
	"accounty/internal/storage/sqlite"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	sqlStorage, err := sqlite.New(cfg.StoragePath)
	if err != nil {
		log.Fatalf("failed to init storage: %s", err)
	}

	gin.SetMode(cfg.Server.RunMode)
	router := gin.New()
	auth.RegisterRoutes(router, sqlStorage)
	users.RegisterRoutes(router, sqlStorage)
	friends.RegisterRoutes(router, sqlStorage)

	server := &http.Server{
		Addr:         cfg.Server.Address,
		Handler:      router,
		ReadTimeout:  cfg.Server.IdleTimeout,
		WriteTimeout: cfg.Server.IdleTimeout,
	}
	log.Printf("[info] start http server listening %s", cfg.Server.Address)

	server.ListenAndServe()
}

// type MigrationSpendingItem struct {
// 	Date        string  `json:"Date"`
// 	Description string  `json:"Description"`
// 	Category    string  `json:"Category"`
// 	Cost        float32 `json:"Cost"`
// 	Currency    string  `json:"Currency"`
// 	Margo       float32 `json:"margo"`
// 	Rzmn        float32 `json:"rzmn"`
// }

// func migrate(db *sqlite.Storage) {
// 	jsonFile, err := os.Open("./data/migration.json")
// 	if err != nil {
// 		fmt.Println(err)
// 		return
// 	}
// 	fmt.Println("Successfully Opened users.json")
// 	defer jsonFile.Close()
// 	byteValue, _ := ioutil.ReadAll(jsonFile)
// 	var items []MigrationSpendingItem
// 	json.Unmarshal(byteValue, &items)
// 	for i := 0; i < len(items); i++ {
// 		format := "2006-01-02"
// 		t, err := time.Parse(format, items[i].Date)
// 		if err != nil {
// 			fmt.Printf("time parse failed %v\n", err)
// 			return
// 		}
// 		fmt.Printf("%s, %v\n", items[i].Date, t)
// 	}
// }
