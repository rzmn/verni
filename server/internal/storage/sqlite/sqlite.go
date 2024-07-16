package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "github.com/mattn/go-sqlite3"
	"golang.org/x/crypto/bcrypt"

	"accounty/internal/storage"
)

type Storage struct {
	db *sql.DB
}

func New(storagePath string) (*Storage, error) {
	const op = "storage.sqlite.New"

	dbDir := filepath.Dir(storagePath)
	err := os.MkdirAll(dbDir, os.ModePerm)

	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	db, err := sql.Open("sqlite3", storagePath)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err := db.Prepare(`
	CREATE TABLE IF NOT EXISTS posts(
		id INTEGER PRIMARY KEY,
		title TEXT NOT NULL,
		content TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS users(
		id INTEGER PRIMARY KEY,
		login TEXT NOT NULL UNIQUE,
		password TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS tokens(
		id INTEGER PRIMARY KEY,
		login TEXT NOT NULL UNIQUE,
		token TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS friendRequests(
		id INTEGER PRIMARY KEY,
		sender TEXT NOT NULL,
		target TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS friends(
		id INTEGER PRIMARY KEY,
		friendA TEXT NOT NULL,
		friendB TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS spendings(
		id INTEGER PRIMARY KEY,
		dealId INTEGER NOT NULL,
		cost INTEGER NOT NULL,
		user TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	stmt, err = db.Prepare(`
	CREATE TABLE IF NOT EXISTS deals(
		id INTEGER PRIMARY KEY,
		timestamp INTEGER NOT NULL,
		details TEXT NOT NULL,
		cost INTEGER NOT NULL,
		currency TEXT NOT NULL
	);`)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	_, err = stmt.Exec()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}

	return &Storage{db: db}, nil
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 10)
	return string(bytes), err
}

func checkPasswordHash(password, hash string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

func (s *Storage) IsLoginExists(login string) (bool, error) {
	const op = "storage.sqlite.IsLoginExists"
	log.Printf("%s: start", op)
	var loginFromDb string
	if err := s.db.QueryRow("SELECT login FROM users where login = ?", login).Scan(&loginFromDb); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return false, nil
		} else {
			log.Printf("%s: cannot check row existence %v", op, err)
			return false, err
		}
	}
	return true, nil
}

func (s *Storage) CheckCredentials(credentials storage.UserCredentials) (bool, error) {
	const op = "storage.sqlite.CheckCredentials"
	log.Printf("%s: start", op)
	var passwordHash string
	if err := s.db.QueryRow("SELECT password FROM users where login = ?", credentials.Login).Scan(&passwordHash); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return false, nil
		} else {
			log.Printf("%s: cannot check row existence %v", op, err)
			return false, err
		}
	}
	return checkPasswordHash(credentials.Password, passwordHash), nil
}

func (s *Storage) StoreCredentials(credentials storage.UserCredentials) error {
	const op = "storage.sqlite.StoreCredentials"
	log.Printf("%s: start", op)
	passwordHash, err := hashPassword(credentials.Password)
	if err != nil {
		log.Printf("%s: cannot hash password %v", op, err)
		return err
	}
	stmt, err := s.db.Prepare("INSERT OR REPLACE INTO users(login, password) VALUES(?, ?)")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}
	_, err = stmt.Exec(credentials.Login, passwordHash)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) GetRefreshToken(login string) (*string, error) {
	const op = "storage.sqlite.GetRefreshToken"
	log.Printf("%s: start", op)
	var token string
	if err := s.db.QueryRow("SELECT token FROM tokens where login = ?", login).Scan(&token); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		} else {
			log.Printf("%s: cannot check row existence %v", op, err)
			return nil, err
		}
	}
	return &token, nil
}

func (s *Storage) StoreRefreshToken(token string, login string) error {
	const op = "storage.sqlite.StoreRefreshToken"
	log.Printf("%s: start", op)
	stmt, err := s.db.Prepare("INSERT OR REPLACE INTO tokens(login, token) VALUES(?, ?)")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}
	_, err = stmt.Exec(login, token)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) RemoveRefreshToken(login string) error {
	const op = "storage.sqlite.RemoveRefreshToken"
	log.Printf("%s: start", op)
	stmt, err := s.db.Prepare("DELETE FROM tokens where login = ?")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}
	_, err = stmt.Exec(login)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) StoreFriendRequest(sender string, target string) error {
	const op = "storage.sqlite.StoreFriendRequest"
	log.Printf("%s: start", op)
	stmt, err := s.db.Prepare("INSERT OR REPLACE INTO friendRequests(sender, target) VALUES(?, ?)")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}
	_, err = stmt.Exec(sender, target)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) HasFriendRequest(sender string, target string) (bool, error) {
	const op = "storage.sqlite.HasFriendRequest"
	log.Printf("%s: start", op)
	var exists bool
	query := "SELECT EXISTS (SELECT 1 FROM friendRequests WHERE sender = ? AND target = ?)"
	if err := s.db.QueryRow(query, sender, target).Scan(&exists); err != nil {
		log.Printf("%s: failed to query %v", op, err)
		return false, err
	}
	return exists, nil
}

func (s *Storage) RemoveFriendRequest(sender string, target string) error {
	const op = "storage.sqlite.RemoveFriendRequest"
	log.Printf("%s: start", op)
	stmt, err := s.db.Prepare("DELETE FROM friendRequests where sender = ? and target = ?")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}
	_, err = stmt.Exec(sender, target)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) StoreFriendship(friendA string, friendB string) error {
	const op = "storage.sqlite.StoreFriendship"
	log.Printf("%s: start", op)
	if friendA > friendB {
		friendA, friendB = friendB, friendA
	}
	stmt, err := s.db.Prepare("INSERT OR REPLACE INTO friends(friendA, friendB) VALUES(?, ?)")
	if err != nil {
		log.Printf("%s: cannot create statement %v", op, err)
		return err
	}

	_, err = stmt.Exec(friendA, friendB)
	if err != nil {
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) HasFriendship(friendA string, friendB string) (bool, error) {
	const op = "storage.sqlite.HasFriendship"
	log.Printf("%s: start", op)
	if friendA > friendB {
		friendA, friendB = friendB, friendA
	}
	var exists bool
	query := "SELECT EXISTS (SELECT 1 FROM friends WHERE friendA = ? AND friendB = ?)"
	if err := s.db.QueryRow(query, friendA, friendB).Scan(&exists); err != nil {
		log.Printf("%s: failed to query %v", op, err)
		return false, err
	}
	return exists, nil
}

func (s *Storage) HasUser(login string) (bool, error) {
	const op = "storage.sqlite.HasUser"
	log.Printf("%s: start", op)
	var exists bool
	query := "SELECT EXISTS (SELECT 1 FROM users WHERE login = ?)"
	if err := s.db.QueryRow(query, login).Scan(&exists); err != nil {
		log.Printf("%s: failed to query %v", op, err)
		return false, err
	}
	return exists, nil
}

func (s *Storage) GetFriends(login string) ([]string, error) {
	const op = "storage.sqlite.GetFriends"
	log.Printf("%s: start", op)
	rows, err := s.db.Query("SELECT friendA, friendB FROM friends WHERE friendA = $1 OR friendB = $1", login)
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()

	var friends []string

	for rows.Next() {
		var friendA, friendB string
		if err := rows.Scan(&friendA, &friendB); err != nil {
			return nil, fmt.Errorf("%s: scan error: %w", op, err)
		}
		if friendA == login {
			friends = append(friends, friendB)
		} else {
			friends = append(friends, friendA)
		}
	}
	if err = rows.Err(); err != nil {
		return friends, err
	}
	return friends, nil
}

func (s *Storage) GetIncomingRequests(login string) ([]string, error) {
	const op = "storage.sqlite.GetIncomingRequests"
	log.Printf("%s: start", op)
	rows, err := s.db.Query("SELECT sender FROM friendRequests WHERE target = ?", login)
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()

	var senders []string
	for rows.Next() {
		var sender string
		if err := rows.Scan(&sender); err != nil {
			return nil, fmt.Errorf("%s: scan error: %w", op, err)
		}
		senders = append(senders, sender)
	}
	if err = rows.Err(); err != nil {
		log.Printf("%s: failed %v", op, err)
		return senders, err
	}
	return senders, nil
}

func (s *Storage) GetPendingRequests(login string) ([]string, error) {
	const op = "storage.sqlite.GetIncomingRequests"
	log.Printf("%s: start", op)
	rows, err := s.db.Query("SELECT target FROM friendRequests WHERE sender = ?", login)
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()

	var targets []string
	for rows.Next() {
		var sender string
		if err := rows.Scan(&sender); err != nil {
			return nil, fmt.Errorf("%s: scan error: %w", op, err)
		}
		targets = append(targets, sender)
	}
	if err = rows.Err(); err != nil {
		log.Printf("%s: failed %v", op, err)
		return targets, err
	}
	return targets, nil
}

func (s *Storage) GetUsers(sender string, ids []string) ([]storage.User, error) {
	const op = "storage.sqlite.GetUsers"

	if len(ids) == 0 {
		return []storage.User{}, nil
	}

	getUsersQuery := "SELECT login FROM users WHERE login in ("
	getUsersQueryArgs := make([]any, len(ids))
	for i := 0; i < len(ids); i++ {
		if i == 0 {
			getUsersQuery = getUsersQuery + "?"
		} else {
			getUsersQuery = getUsersQuery + ", ?"
		}
		getUsersQueryArgs[i] = ids[i]
	}
	getUsersQuery = getUsersQuery + ")"
	rows, err := s.db.Query(getUsersQuery, getUsersQueryArgs...)
	if err != nil {
		return nil, fmt.Errorf("%s: create query %s: %w", op, getUsersQuery, err)
	}
	var userIds []string
	for rows.Next() {
		var sender string
		if err := rows.Scan(&sender); err != nil {
			return nil, fmt.Errorf("%s: scan error: %w", op, err)
		}
		userIds = append(userIds, sender)
	}
	if err = rows.Err(); err != nil {
		log.Printf("%s: filter for existence failed %v", op, err)
		return []storage.User{}, err
	}
	log.Printf("%s: found %d users", op, len(userIds))

	pendingFriends, err := s.GetPendingRequests(sender)
	if err != nil {
		log.Printf("%s: get pending friends failed %v", op, err)
	}
	pendingFriendsMap := map[string]bool{}
	for i := 0; i < len(pendingFriends); i++ {
		pendingFriendsMap[pendingFriends[i]] = true
	}
	incomingFriends, err := s.GetIncomingRequests(sender)
	if err != nil {
		log.Printf("%s: get incoming friends failed %v", op, err)
	}
	incomingFriendsMap := map[string]bool{}
	for i := 0; i < len(incomingFriends); i++ {
		incomingFriendsMap[incomingFriends[i]] = true
	}
	friends, err := s.GetFriends(sender)
	if err != nil {
		log.Printf("%s: get friends failed %v", op, err)
	}
	friendsMap := map[string]bool{}
	for i := 0; i < len(friends); i++ {
		friendsMap[friends[i]] = true
	}

	users := make([]storage.User, len(userIds))
	for i := 0; i < len(userIds); i++ {
		var status storage.FriendStatus
		if userIds[i] == sender {
			status = storage.FriendStatusMe
		} else if pendingFriendsMap[userIds[i]] {
			status = storage.FriendStatusOutgoingRequest
		} else if incomingFriendsMap[userIds[i]] {
			status = storage.FriendStatusIncomingRequest
		} else if friendsMap[userIds[i]] {
			status = storage.FriendStatusFriends
		} else {
			status = storage.FriendStatusNo
		}
		users[i] = storage.User{
			Login:        storage.UserId(userIds[i]),
			FriendStatus: status,
		}
	}
	return users, nil
}

func (s *Storage) SearchUsers(sender string, query string) ([]storage.User, error) {
	const op = "storage.sqlite.SearchUsers"
	log.Printf("%s: start", op)
	rows, err := s.db.Query(fmt.Sprintf("SELECT login FROM users WHERE login LIKE '%s%%' ORDER BY login", query))
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()

	var targets []string
	for rows.Next() {
		var sender string
		if err := rows.Scan(&sender); err != nil {
			return nil, fmt.Errorf("%s: scan error: %w", op, err)
		}
		targets = append(targets, sender)
	}
	if err = rows.Err(); err != nil {
		log.Printf("%s: failed %v", op, err)
		return nil, err
	}
	return s.GetUsers(sender, targets)
}

func (s *Storage) InsertDeal(deal storage.Deal) error {
	const op = "storage.sqlite.InsertDeal"
	log.Printf("%s: start", op)

	ctx := context.Background()
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		log.Printf("%s: cannot create transaction %v", op, err)
		return err
	}
	result, err := tx.Exec("INSERT INTO deals(timestamp, details, cost, currency) VALUES(?, ?, ?, ?)", deal.Timestamp, deal.Details, deal.Cost, deal.Currency)
	if err != nil {
		tx.Rollback()
		log.Printf("%s: cannot execute statement %v", op, err)
		return err
	}
	dealId, err := result.LastInsertId()
	if err != nil {
		tx.Rollback()
		log.Printf("%s: cannot get inserted id %v", op, err)
		return err
	}
	for i := 0; i < len(deal.Spendings); i++ {
		spending := deal.Spendings[i]
		_, err = tx.Exec("INSERT INTO spendings(dealId, cost, user) VALUES(?, ?, ?)", dealId, spending.Cost, spending.UserId)
		if err != nil {
			tx.Rollback()
			log.Printf("%s: cannot insert spending %v", op, err)
			return err
		}
	}
	if err := tx.Commit(); err != nil {
		log.Printf("%s: failed to commit transaction %v", op, err)
		return err
	}
	return nil
}

func (s *Storage) GetDeals(counterparty1 string, counterparty2 string) ([]storage.IdentifiableDeal, error) {
	const op = "storage.sqlite.GetDeals"
	log.Printf("%s: start", op)
	rows, err := s.db.Query(fmt.Sprintf(`SELECT
  s1.dealId,
  s1.user,
  s1.cost,
  s2.user,
  s2.cost,
  d.timestamp,
  d.details,
  d.cost,
  d.currency
FROM
  spendings s1
  JOIN spendinds s2 ON s1.dealId = s2.dealId
  JOIN deals d ON s1.dealId = d.id
  AND s1.user in (%[1]s, %[2]s)
  AND s2.user in (%[1]s, %[2]s)`, counterparty1, counterparty2))
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()
	var deals []storage.IdentifiableDeal
	for rows.Next() {
		deal := storage.IdentifiableDeal{}
		if err := rows.Scan(&deal.Id); err != nil {
			return nil, fmt.Errorf("%s: scan deal id error: %w", op, err)
		}
		for i := 0; i < 2; i++ {
			spending := storage.Spending{}
			if err := rows.Scan(&spending.UserId); err != nil {
				return nil, fmt.Errorf("%s: scan spending user id error: %w", op, err)
			}
			if err := rows.Scan(&spending.Cost); err != nil {
				return nil, fmt.Errorf("%s: scan spending cost error: %w", op, err)
			}
			deal.Spendings = append(deal.Spendings, spending)
		}
		if err := rows.Scan(&deal.Timestamp); err != nil {
			return nil, fmt.Errorf("%s: scan deal timestamp error: %w", op, err)
		}
		if err := rows.Scan(&deal.Details); err != nil {
			return nil, fmt.Errorf("%s: scan deal details error: %w", op, err)
		}
		if err := rows.Scan(&deal.Cost); err != nil {
			return nil, fmt.Errorf("%s: scan deal cost error: %w", op, err)
		}
		if err := rows.Scan(&deal.Currency); err != nil {
			return nil, fmt.Errorf("%s: scan deal currency error: %w", op, err)
		}
		deals = append(deals, deal)
	}
	if err = rows.Err(); err != nil {
		log.Printf("%s: failed %v", op, err)
		return nil, err
	}
	return deals, nil
}

func (s *Storage) GetCounterparties(target string) ([]storage.SpendingsPreview, error) {
	const op = "storage.sqlite.GetCounterparties"
	log.Printf("%s: start", op)
	rows, err := s.db.Query(fmt.Sprintf(`SELECT
  d.currency,
  s2.user,
  s1.cost
FROM
  deals d
  JOIN spendings s1 ON s1.dealId = d.id AND s1.user = %[1]s
  JOIN spendinds s2 ON s2.dealId = d.id AND s2.user != %[1]s`, target))
	if err != nil {
		return nil, fmt.Errorf("%s: create query: %w", op, err)
	}
	defer rows.Close()
	spendingsMap := map[string]storage.SpendingsPreview{}
	for rows.Next() {
		var currency string
		if err := rows.Scan(&currency); err != nil {
			return nil, fmt.Errorf("%s: scan currency error: %w", op, err)
		}
		var counterparty string
		if err := rows.Scan(&counterparty); err != nil {
			return nil, fmt.Errorf("%s: scan counterparty error: %w", op, err)
		}
		var targetsCost int
		if err := rows.Scan(&targetsCost); err != nil {
			return nil, fmt.Errorf("%s: scan targetsCost error: %w", op, err)
		}
		spendingsMap[counterparty].Balance[currency] += targetsCost
	}
	spendings := make([]storage.SpendingsPreview, 0, len(spendingsMap))

	for _, value := range spendingsMap {
		spendings = append(spendings, value)
	}
	return spendings, nil
}

func (s *Storage) Close() {
	log.Printf("storage closed")
}
