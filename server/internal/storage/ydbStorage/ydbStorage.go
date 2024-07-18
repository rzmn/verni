package ydbStorage

import (
	"context"
	"fmt"
	"log"
	"path"

	"golang.org/x/crypto/bcrypt"

	"accounty/internal/storage"

	"github.com/google/uuid"
	"github.com/ydb-platform/ydb-go-sdk/v3"
	"github.com/ydb-platform/ydb-go-sdk/v3/table"
	"github.com/ydb-platform/ydb-go-sdk/v3/table/options"
	"github.com/ydb-platform/ydb-go-sdk/v3/table/result"
	"github.com/ydb-platform/ydb-go-sdk/v3/table/types"
)

type Storage struct {
	db  *ydb.Driver
	ctx context.Context
}

func NewUnauthorized(storagePath string) (storage.Storage, error) {
	const op = "storage.ydb.NewUnauthorized"
	ctx := context.Background()
	db, err := ydb.Open(ctx, storagePath)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}
	log.Printf("%s: connection created", op)
	return new(ctx, db)
}

func New(storagePath string, token string) (storage.Storage, error) {
	const op = "storage.ydb.New"
	ctx := context.Background()
	db, err := ydb.Open(ctx, storagePath, ydb.WithAccessTokenCredentials(token))
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}
	log.Printf("%s: connection created", op)
	return new(ctx, db)
}

func new(ctx context.Context, db *ydb.Driver) (storage.Storage, error) {
	const op = "storage.ydb.new"
	err := db.Table().Do(ctx,
		func(ctx context.Context, s table.Session) (err error) {
			if err := s.CreateTable(ctx, path.Join(db.Name(), "users"),
				options.WithColumn("login", types.TypeText),
				options.WithColumn("password", types.TypeText),
				options.WithPrimaryKeyColumn("login"),
			); err != nil {
				return err
			}
			if err := s.CreateTable(ctx, path.Join(db.Name(), "tokens"),
				options.WithColumn("login", types.TypeText),
				options.WithColumn("token", types.TypeText),
				options.WithPrimaryKeyColumn("login"),
			); err != nil {
				return err
			}
			if err := s.CreateTable(ctx, path.Join(db.Name(), "friendRequests"),
				options.WithColumn("sender", types.TypeText),
				options.WithColumn("target", types.TypeText),
				options.WithPrimaryKeyColumn("sender", "target"),
			); err != nil {
				return err
			}
			if err := s.CreateTable(ctx, path.Join(db.Name(), "friends"),
				options.WithColumn("friendA", types.TypeText),
				options.WithColumn("friendB", types.TypeText),
				options.WithPrimaryKeyColumn("friendA", "friendB"),
			); err != nil {
				return err
			}
			if err := s.CreateTable(ctx, path.Join(db.Name(), "spendings"),
				options.WithColumn("id", types.TypeText),
				options.WithColumn("dealId", types.TypeText),
				options.WithColumn("cost", types.TypeInt64),
				options.WithColumn("counterparty", types.TypeText),
				options.WithPrimaryKeyColumn("id"),
			); err != nil {
				return err
			}
			if err := s.CreateTable(ctx, path.Join(db.Name(), "deals"),
				options.WithColumn("id", types.TypeText),
				options.WithColumn("timestamp", types.TypeInt64),
				options.WithColumn("details", types.TypeText),
				options.WithColumn("cost", types.TypeInt64),
				options.WithColumn("currency", types.TypeText),
				options.WithPrimaryKeyColumn("id"),
			); err != nil {
				return err
			}
			return nil
		},
	)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", op, err)
	}
	return &Storage{db: db, ctx: ctx}, nil
}

func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 10)
	return string(bytes), err
}

func checkPasswordHash(password, hash string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

func (s *Storage) IsUserExists(uid storage.UserId) (bool, error) {
	const op = "storage.ydb.IsUserExists"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		exists bool
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, readTx, `
DECLARE $login AS Text;
SELECT 
	True
FROM 
	users 
WHERE 
	login = $login`,
			table.NewQueryParameters(table.ValueParam("$login", types.TextValue(string(uid)))),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				if err := res.Scan(&exists); err != nil {
					return err
				}
			}
		}
		if err := res.Err(); err != nil {
			return err
		}
		return res.Err()
	})
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (s *Storage) CheckCredentials(credentials storage.UserCredentials) (bool, error) {
	const op = "storage.ydb.CheckCredentials"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		res    result.Result
		passed bool
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err = s.Execute(ctx, readTx, `
DECLARE $login AS Text;
SELECT password FROM users where login = $login;`,
			table.NewQueryParameters(table.ValueParam("$login", types.TextValue(string(credentials.Login)))),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				var passwordHash string
				err = res.Scan(&passwordHash)
				if err != nil {
					return err
				}
				if checkPasswordHash(credentials.Password, passwordHash) {
					passed = true
					return res.Err()
				}
			}
		}
		return res.Err()
	})
	if err != nil {
		return false, err
	}
	return passed, nil
}

func (s *Storage) StoreCredentials(credentials storage.UserCredentials) error {
	const op = "storage.ydb.StoreCredentials"
	log.Printf("%s: start", op)
	passwordHash, err := hashPassword(credentials.Password)
	if err != nil {
		log.Printf("%s: cannot hash password %v", op, err)
		return err
	}
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err = s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $login AS Text;
DECLARE $password AS Text;
UPSERT INTO 
	users(login, password) 
VALUES($login, $password)`,
			table.NewQueryParameters(
				table.ValueParam("$login", types.TextValue(string(credentials.Login))),
				table.ValueParam("$password", types.TextValue(passwordHash)),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) GetRefreshToken(uid storage.UserId) (*string, error) {
	const op = "storage.ydb.GetRefreshToken"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		res    result.Result
		token  *string
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err = s.Execute(ctx, readTx, `
DECLARE $login AS Text;
SELECT token FROM tokens where login = $login;`,
			table.NewQueryParameters(
				table.ValueParam("$login", types.TextValue(string(uid))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				var value string
				err = res.Scan(&value)
				if err != nil {
					return err
				}
				token = &value
			}
		}
		return res.Err()
	})
	if err != nil {
		return nil, err
	}
	return token, nil
}

func (s *Storage) StoreRefreshToken(token string, uid storage.UserId) error {
	const op = "storage.ydb.StoreRefreshToken"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $login AS Text;
DECLARE $token AS Text;
UPSERT INTO 
	tokens(login, token) 
VALUES($login, $token)`,
			table.NewQueryParameters(
				table.ValueParam("$login", types.TextValue(string(uid))),
				table.ValueParam("$token", types.TextValue(token)),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) RemoveRefreshToken(uid storage.UserId) error {
	const op = "storage.ydb.RemoveRefreshToken"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $login AS Text;
DELETE FROM 
	tokens 
WHERE 
	login = $login`,
			table.NewQueryParameters(
				table.ValueParam("$login", types.TextValue(string(uid))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) StoreFriendRequest(sender storage.UserId, target storage.UserId) error {
	const op = "storage.ydb.StoreFriendRequest"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $sender AS Text;
DECLARE $target AS Text;
UPSERT INTO 
	friendRequests(sender, target) 
VALUES($sender, $target)`,
			table.NewQueryParameters(
				table.ValueParam("$sender", types.TextValue(string(sender))),
				table.ValueParam("$target", types.TextValue(string(target))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) HasFriendRequest(sender storage.UserId, target storage.UserId) (bool, error) {
	const op = "storage.ydb.HasFriendRequest"
	log.Printf("%s: start", op)
	var (
		readTx     = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		res        result.Result
		hasRequest bool
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err = s.Execute(ctx, readTx, `
DECLARE $sender AS Text;
DECLARE $target AS Text;
SELECT 
	True 
FROM 
	friendRequests 
WHERE 
	sender = $sender AND target = $target`,
			table.NewQueryParameters(
				table.ValueParam("$sender", types.TextValue(string(sender))),
				table.ValueParam("$target", types.TextValue(string(target))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				if err := res.Scan(&hasRequest); err != nil {
					return err
				}
			}
		}
		return res.Err()
	})
	if err != nil {
		return false, err
	}
	return hasRequest, nil
}

func (s *Storage) RemoveFriendRequest(sender storage.UserId, target storage.UserId) error {
	const op = "storage.ydb.RemoveFriendRequest"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $sender AS Text;
DECLARE $target AS Text;
DELETE FROM 
	friendRequests 
WHERE 
	sender = $sender and target = $target`,
			table.NewQueryParameters(
				table.ValueParam("$sender", types.TextValue(string(sender))),
				table.ValueParam("$target", types.TextValue(string(target))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) StoreFriendship(friendA storage.UserId, friendB storage.UserId) error {
	const op = "storage.ydb.StoreFriendship"
	log.Printf("%s: start", op)
	if friendA > friendB {
		friendA, friendB = friendB, friendA
	}
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $friendA AS Text;
DECLARE $friendB AS Text;
UPSERT INTO 
	friends(friendA, friendB) 
VALUES($friendA, $friendB)`,
			table.NewQueryParameters(
				table.ValueParam("$friendA", types.TextValue(string(friendA))),
				table.ValueParam("$friendB", types.TextValue(string(friendB))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) HasFriendship(friendA storage.UserId, friendB storage.UserId) (bool, error) {
	const op = "storage.ydb.HasFriendship"
	log.Printf("%s: start", op)
	if friendA > friendB {
		friendA, friendB = friendB, friendA
	}
	var (
		readTx        = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		res           result.Result
		hasFriendship bool
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err = s.Execute(ctx, readTx, `
DECLARE $friendA AS Text;
DECLARE $friendB AS Text;
SELECT 
	True 
FROM 
	friends 
WHERE 
	friendA = $friendA AND friendB = $friendB`,
			table.NewQueryParameters(
				table.ValueParam("$friendA", types.TextValue(string(friendA))),
				table.ValueParam("$friendB", types.TextValue(string(friendB))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				if err := res.Scan(&hasFriendship); err != nil {
					return err
				}
			}
		}
		return res.Err()
	})
	if err != nil {
		return false, err
	}
	return hasFriendship, nil
}

func (s *Storage) RemoveFriendship(friendA storage.UserId, friendB storage.UserId) error {
	const op = "storage.ydb.RemoveFriendship"
	log.Printf("%s: start", op)
	if friendA > friendB {
		friendA, friendB = friendB, friendA
	}
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $friendA AS Text;
DECLARE $friendB AS Text;
DELETE FROM 
	friends 
WHERE 
	friendA = $friendA AND friendB = $friendB`,
			table.NewQueryParameters(
				table.ValueParam("$friendA", types.TextValue(string(friendA))),
				table.ValueParam("$friendB", types.TextValue(string(friendB))),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) GetFriends(uid storage.UserId) ([]storage.UserId, error) {
	const op = "storage.ydb.GetFriends"
	log.Printf("%s: start", op)
	var (
		readTx  = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		friends []storage.UserId
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			_, res, err := s.Execute(ctx, readTx, `
DECLARE $user AS Text;
SELECT 
	friendA, friendB 
FROM 
	friends 
WHERE 
	friendA = $user OR friendB = $user`,
				table.NewQueryParameters(
					table.ValueParam("$user", types.TextValue(string(uid))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					var friendA, friendB string
					if err := res.Scan(&friendA, &friendB); err != nil {
						return err
					}
					if friendA == string(uid) {
						friends = append(friends, storage.UserId(friendB))
					} else {
						friends = append(friends, storage.UserId(friendA))
					}
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return friends, err
	}
	return friends, nil
}

func (s *Storage) GetIncomingRequests(uid storage.UserId) ([]storage.UserId, error) {
	const op = "storage.ydb.GetIncomingRequests"
	log.Printf("%s: start", op)
	var (
		readTx  = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		senders []storage.UserId
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			_, res, err := s.Execute(ctx, readTx, `
DECLARE $target AS Text;
SELECT 
	sender 
FROM 
	friendRequests 
WHERE 
	target = $target`,
				table.NewQueryParameters(
					table.ValueParam("$target", types.TextValue(string(uid))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					var sender string
					if err := res.Scan(&sender); err != nil {
						return err
					}
					senders = append(senders, storage.UserId(sender))
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return senders, err
	}
	return senders, nil
}

func (s *Storage) GetPendingRequests(uid storage.UserId) ([]storage.UserId, error) {
	const op = "storage.ydb.GetIncomingRequests"
	log.Printf("%s: start", op)
	var (
		readTx  = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		targets []storage.UserId
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			_, res, err := s.Execute(ctx, readTx, `
DECLARE $sender AS Text;
SELECT 
	target 
FROM 
	friendRequests 
WHERE 
	sender = $sender`,
				table.NewQueryParameters(
					table.ValueParam("$sender", types.TextValue(string(uid))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					var target string
					if err := res.Scan(&target); err != nil {
						return err
					}
					targets = append(targets, storage.UserId(target))
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return targets, err
	}
	return targets, nil
}

func (s *Storage) filterInvalidUsers(ids []storage.UserId) ([]storage.UserId, error) {
	const op = "storage.ydb.filterInvalidUsers"
	log.Printf("%s: start", op)
	var (
		readTx     = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		unfiltered []types.Value
		uids       []storage.UserId
	)
	for i := 0; i < len(ids); i++ {
		unfiltered = append(unfiltered, types.TextValue(string(ids[i])))
	}
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			_, res, err := s.Execute(ctx, readTx, `
DECLARE $uids AS List<Text>;
SELECT 
	login 
FROM 
	users 
WHERE 
	login in $uids`,
				table.NewQueryParameters(
					table.ValueParam("$uids", types.ListValue(unfiltered...)),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					var uid string
					if err := res.Scan(&uid); err != nil {
						return err
					}
					uids = append(uids, storage.UserId(uid))
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return uids, err
	}
	return uids, nil
}

func (s *Storage) GetUsers(sender storage.UserId, ids []storage.UserId) ([]storage.User, error) {
	const op = "storage.ydb.GetUsers"
	log.Printf("%s: start", op)
	if len(ids) == 0 {
		return []storage.User{}, nil
	}
	userIds, err := s.filterInvalidUsers(ids)
	if err != nil {
		return []storage.User{}, err
	}
	log.Printf("%s: found %d users", op, len(userIds))

	pendingFriends, err := s.GetPendingRequests(sender)
	if err != nil {
		log.Printf("%s: get pending friends failed %v", op, err)
	}
	pendingFriendsMap := map[storage.UserId]bool{}
	for i := 0; i < len(pendingFriends); i++ {
		pendingFriendsMap[pendingFriends[i]] = true
	}
	incomingFriends, err := s.GetIncomingRequests(sender)
	if err != nil {
		log.Printf("%s: get incoming friends failed %v", op, err)
	}
	incomingFriendsMap := map[storage.UserId]bool{}
	for i := 0; i < len(incomingFriends); i++ {
		incomingFriendsMap[incomingFriends[i]] = true
	}
	friends, err := s.GetFriends(sender)
	if err != nil {
		log.Printf("%s: get friends failed %v", op, err)
	}
	friendsMap := map[storage.UserId]bool{}
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

func (s *Storage) SearchUsers(sender storage.UserId, query string) ([]storage.User, error) {
	const op = "storage.ydb.SearchUsers"
	log.Printf("%s: start", op)
	if len(query) == 0 {
		return []storage.User{}, nil
	}
	var (
		readTx  = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		targets []storage.UserId
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			_, res, err := s.Execute(ctx, readTx, fmt.Sprintf(`
DECLARE $query AS Text;
SELECT 
	login 
FROM 
	users 
WHERE 
	login LIKE '%s%%' or login = $query ORDER BY login`, query),
				table.NewQueryParameters(
					table.ValueParam("$query", types.TextValue(query)),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					var sender string
					if err := res.Scan(&sender); err != nil {
						return err
					}
					targets = append(targets, storage.UserId(sender))
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return []storage.User{}, err
	}
	return s.GetUsers(sender, targets)
}

func (s *Storage) InsertDeal(deal storage.Deal) error {
	const op = "storage.ydb.InsertDeal"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
		dealId = uuid.New().String()
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $id AS Text;
DECLARE $timestamp AS Int64;
DECLARE $details AS Text;
DECLARE $cost AS Int64;
DECLARE $currency AS Text;
INSERT INTO 
	deals(id, timestamp, details, cost, currency) 
VALUES($id, $timestamp, $details, $cost, $currency)`,
			table.NewQueryParameters(
				table.ValueParam("$id", types.TextValue(dealId)),
				table.ValueParam("$timestamp", types.Int64Value(deal.Timestamp)),
				table.ValueParam("$details", types.TextValue(deal.Details)),
				table.ValueParam("$cost", types.Int64Value(int64(deal.Cost))),
				table.ValueParam("$currency", types.TextValue(deal.Currency)),
			),
		)
		if err != nil {
			return err
		}

		defer res.Close()
		for i := 0; i < len(deal.Spendings); i++ {
			_, res, err := s.Execute(ctx, writeTx, `
DECLARE $id AS Text;
DECLARE $dealId AS Text;
DECLARE $cost AS Int64;
DECLARE $counterparty AS Text;
INSERT INTO 
	spendings(id, dealId, cost, counterparty) 
VALUES($id, $dealId, $cost, $counterparty)`,
				table.NewQueryParameters(
					table.ValueParam("$id", types.TextValue(uuid.New().String())),
					table.ValueParam("$dealId", types.TextValue(dealId)),
					table.ValueParam("$cost", types.Int64Value(int64(deal.Spendings[i].Cost))),
					table.ValueParam("$counterparty", types.TextValue(string(deal.Spendings[i].UserId))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
		}
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) HasDeal(did string) (bool, error) {
	const op = "storage.ydb.HasDeal"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(table.BeginTx(table.WithOnlineReadOnly()), table.CommitTx())
		exists bool
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, readTx, `
DECLARE $id AS Text;
SELECT 
	True
FROM 
	deals 
WHERE 
	id = $id`,
			table.NewQueryParameters(table.ValueParam("$id", types.TextValue(did))),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		for res.NextResultSet(ctx) {
			for res.NextRow() {
				if err := res.Scan(&exists); err != nil {
					return err
				}
			}
		}
		if err := res.Err(); err != nil {
			return err
		}
		return res.Err()
	})
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (s *Storage) RemoveDeal(did string) error {
	const op = "storage.ydb.RemoveDeal"
	log.Printf("%s: start", op)
	var (
		writeTx = table.TxControl(
			table.BeginTx(
				table.WithSerializableReadWrite(),
			),
			table.CommitTx(),
		)
	)
	err := s.db.Table().Do(s.ctx, func(ctx context.Context, s table.Session) (err error) {
		_, res, err := s.Execute(ctx, writeTx, `
DECLARE $id AS Text;
DELETE FROM 
	deals 
WHERE 
	id = $id`,
			table.NewQueryParameters(
				table.ValueParam("$id", types.TextValue(did)),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		_, res, err = s.Execute(ctx, writeTx, `
DECLARE $id AS Text;
DELETE FROM 
	spendings 
WHERE 
	dealId = $id`,
			table.NewQueryParameters(
				table.ValueParam("$id", types.TextValue(did)),
			),
		)
		if err != nil {
			return err
		}
		defer res.Close()
		return res.Err()
	})
	if err != nil {
		return err
	}
	return nil
}

func (s *Storage) GetDeals(counterparty1 storage.UserId, counterparty2 storage.UserId) ([]storage.IdentifiableDeal, error) {
	const op = "storage.ydb.GetDeals"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(
			table.BeginTx(
				table.WithOnlineReadOnly(),
			),
			table.CommitTx(),
		)
		deals = []storage.IdentifiableDeal{}
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			var (
				res result.Result
			)
			_, res, err = s.Execute(ctx, readTx, `
DECLARE $counterparty1 AS Text;
DECLARE $counterparty2 AS Text;
SELECT
  s1.dealId,
  s1.counterparty,
  s1.cost,
  s2.counterparty,
  s2.cost,
  d.timestamp,
  d.details,
  d.cost,
  d.currency
FROM
  spendings s1
  JOIN spendings s2 ON s1.dealId = s2.dealId
  JOIN deals d ON s1.dealId = d.id
WHERE
  s1.counterparty = $counterparty1 AND s2.counterparty = $counterparty2`,
				table.NewQueryParameters(
					table.ValueParam("$counterparty1", types.TextValue(string(counterparty1))),
					table.ValueParam("$counterparty2", types.TextValue(string(counterparty2))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			log.Printf("> select_simple_transaction:\n")
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					deal := storage.IdentifiableDeal{}
					deal.Spendings = make([]storage.Spending, 2)
					err = res.Scan(
						&deal.Id,
						&deal.Spendings[0].UserId,
						&deal.Spendings[0].Cost,
						&deal.Spendings[1].UserId,
						&deal.Spendings[1].Cost,
						&deal.Timestamp,
						&deal.Details,
						&deal.Cost,
						&deal.Currency)
					if err != nil {
						return err
					}
					deals = append(deals, deal)
				}
			}
			return res.Err()
		},
	)
	if err != nil {
		return deals, err
	}
	return deals, nil
}

func (s *Storage) GetCounterparties(target storage.UserId) ([]storage.SpendingsPreview, error) {
	const op = "storage.ydb.GetCounterparties"
	log.Printf("%s: start", op)
	var (
		readTx = table.TxControl(
			table.BeginTx(
				table.WithOnlineReadOnly(),
			),
			table.CommitTx(),
		)
		spendingsMap = map[string]storage.SpendingsPreview{}
	)
	err := s.db.Table().Do(s.ctx,
		func(ctx context.Context, s table.Session) (err error) {
			var (
				res      result.Result
				currency string
				user     string
				cost     int64
			)
			_, res, err = s.Execute(ctx, readTx, `
DECLARE $target AS Text;
SELECT
  d.currency,
  s2.counterparty,
  s1.cost
FROM
  deals d
  JOIN spendings s1 ON s1.dealId = d.id
  JOIN spendings s2 ON s2.dealId = d.id
WHERE 
  s1.counterparty = $target AND s2.counterparty != $target`,
				table.NewQueryParameters(
					table.ValueParam("$target", types.TextValue(string(target))),
				),
			)
			if err != nil {
				return err
			}
			defer res.Close()
			for res.NextResultSet(ctx) {
				for res.NextRow() {
					err = res.Scan(
						&currency,
						&user,
						&cost,
					)
					if err != nil {
						return err
					}
					_, ok := spendingsMap[user]
					if !ok {
						spendingsMap[user] = storage.SpendingsPreview{
							Counterparty: user,
							Balance:      map[string]int64{},
						}
					}
					spendingsMap[user].Balance[currency] += cost
				}
			}
			return res.Err()
		},
	)
	spendings := make([]storage.SpendingsPreview, 0, len(spendingsMap))
	if err != nil {
		return spendings, err
	}

	for _, value := range spendingsMap {
		spendings = append(spendings, value)
	}
	return spendings, nil
}

func (s *Storage) Close() {
	log.Printf("storage closed")
	s.db.Close(s.ctx)
}
