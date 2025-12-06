package services

import (
	"fmt"
	"net/smtp"
	"os"
)

func SendEmail(to, subject, body string) error {
	from := os.Getenv("SMTP_EMAIL")
	password := os.Getenv("SMTP_PASSWORD")
	host := "smtp.gmail.com"
	port := "587"

	if from == "" || password == "" {
		return fmt.Errorf("SMTP credentials not set")
	}

	auth := smtp.PlainAuth("", from, password, host)

	msg := []byte(fmt.Sprintf("To: %s\r\nSubject: %s\r\n\r\n%s", to, subject, body))

	return smtp.SendMail(host+":"+port, auth, from, []string{to}, msg)
}
