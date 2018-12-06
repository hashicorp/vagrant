package ssh

import (
	"golang.org/x/crypto/ssh"
)

// An implementation of ssh.KeyboardInteractiveChallenge that simply sends
// back the password for all questions. The questions are logged.
func PasswordKeyboardInteractive(password string) ssh.KeyboardInteractiveChallenge {
	return func(user, instruction string, questions []string, echos []bool) ([]string, error) {
		logger.Info("keyboard interactive challenge", "user", user,
			"instructions", instruction)
		for i, question := range questions {
			logger.Info("challenge question", "number", i+1, "question", question)
		}

		// Just send the password back for all questions
		answers := make([]string, len(questions))
		for i := range answers {
			answers[i] = password
		}

		return answers, nil
	}
}
