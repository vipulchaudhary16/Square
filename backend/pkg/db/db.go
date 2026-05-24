package db

import (
	"context"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/event"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var Client *mongo.Client
var DB *mongo.Database

func Connect() {
	uri := os.Getenv("MONGO_URI")
	if uri == "" {
		uri = "mongodb://localhost:27017"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	monitor := &event.CommandMonitor{
		Started: func(_ context.Context, evt *event.CommandStartedEvent) {
			log.Printf("DB Command Started: %s | Command: %v", evt.CommandName, evt.Command)
		},
		Succeeded: func(_ context.Context, evt *event.CommandSucceededEvent) {
			log.Printf("DB Command Succeeded: %s | Duration: %v", evt.CommandName, evt.Duration)
		},
		Failed: func(_ context.Context, evt *event.CommandFailedEvent) {
			log.Printf("DB Command Failed: %s | Duration: %v | Error: %v", evt.CommandName, evt.Duration, evt.Failure)
		},
	}

	clientOptions := options.Client().ApplyURI(uri).SetMonitor(monitor)
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatal(err)
	}

	Client = client
	DB = client.Database("expense_tracker")
	log.Println("Connected to MongoDB!")

	// Ensure unique index on feature_flag_registry.key
	indexModel := mongo.IndexModel{
		Keys:    bson.D{{Key: "key", Value: 1}},
		Options: options.Index().SetUnique(true),
	}
	if _, err := DB.Collection("feature_flag_registry").Indexes().CreateOne(context.Background(), indexModel); err != nil {
		log.Printf("Warning: could not create unique index on feature_flag_registry.key: %v", err)
	}
}

func GetContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), 30*time.Second)
}
