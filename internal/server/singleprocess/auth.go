package singleprocess

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/subtle"
	"io"
	"strings"
	"time"

	"github.com/mr-tron/base58"
	"github.com/pkg/errors"
	"golang.org/x/crypto/blake2b"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

const (
	// The user that all tokens are encoded with. The server has a single server model
	// so all actions are mapped to this user.
	DefaultUser = "vagrant"

	// The identifier for the default key to use to generating tokens.
	DefaultKeyId = "k1"

	// Used as a byte sequence prepended to the encoded TokenTransport to identify
	// the token as valid before attempting to decode it. This is mostly a nicity to improve
	// understanding of the token data and error messages.
	tokenMagic = "wp24"

	// The size in bytes that the HMAC keys should be. Each key will contain this number of bytes
	// of data from rand.Reader
	hmacKeySize = 32

	// A prefix added to the key id when looking up the HMAC key from the database
	dbKeyPrefix = "hmacKey:"
)

var (
	ErrInvalidToken = errors.New("invalid authentication token")
)

// DecodeToken parses the string and validates it as a valid token. If the token
// has a validity period attached to it, the period is checked here.
func (s *service) DecodeToken(token string) (*vagrant_server.TokenTransport, *vagrant_server.Token, error) {
	data, err := base58.Decode(token)
	if err != nil {
		return nil, nil, err
	}

	if subtle.ConstantTimeCompare(data[:len(tokenMagic)], []byte(tokenMagic)) != 1 {
		return nil, nil, errors.Wrapf(ErrInvalidToken, "bad magic")
	}

	var tt vagrant_server.TokenTransport
	err = proto.Unmarshal(data[len(tokenMagic):], &tt)
	if err != nil {
		return nil, nil, err
	}

	key, err := s.state.HMACKeyGet(tt.KeyId)
	if err != nil || key == nil {
		return nil, nil, errors.Wrapf(ErrInvalidToken, "unknown key")
	}

	h, err := blake2b.New256(key.Key)
	if err != nil {
		return nil, nil, err
	}

	h.Write(tt.Body)

	sum := h.Sum(nil)

	if subtle.ConstantTimeCompare(sum, tt.Signature) != 1 {
		return nil, nil, errors.Wrapf(ErrInvalidToken, "bad signature")
	}

	var body vagrant_server.Token

	err = proto.Unmarshal(tt.Body, &body)
	if err != nil {
		return nil, nil, err
	}

	if body.ValidUntil != nil {
		vt := time.Unix(body.ValidUntil.Seconds, int64(body.ValidUntil.Nanos))

		now := time.Now()
		if vt.Before(now.UTC()) {
			return nil, nil, errors.Wrapf(ErrInvalidToken, "token has expired. %s < %s", vt, now)
		}
	}

	return &tt, &body, nil
}

// Authenticate checks if the given endpoint should be allowed. This is called during a
// gRPC request. Effects is some information about the endpoint, at present these are
// either ["readonly"] or ["mutable"] to indicate if the endpoint will be only reading
// data or also mutating it.
func (s *service) Authenticate(ctx context.Context, token, endpoint string, effects []string) error {
	// We always allow ConvertInviteToken so that folks can actually get authentication data
	if endpoint == "ConvertInviteToken" || endpoint == "BootstrapToken" || endpoint == "GetVersionInfo" {
		return nil
	}

	if token == "" {
		return status.Errorf(codes.Unauthenticated, "Authorization token is not supplied")
	}

	_, body, err := s.DecodeToken(token)
	if err != nil {
		return err
	}

	if !body.Login {
		return ErrInvalidToken
	}

	// If this is an entrypoint token then we can only access entrypoint APIs.
	if body.Entrypoint != nil && !strings.HasPrefix(endpoint, "Entrypoint") {
		return status.Errorf(codes.Unauthenticated, "Unauthorized endpoint")
	}

	// TODO When we have a user model, this is where you'll check for the user.
	if body.User != DefaultUser {
		return ErrInvalidToken
	}

	return nil
}

// Generate a new token by signing the data in body.
// keyId controls which key is used to sign the key (key values are generated lazily).
// metadata is attached to the token transport as configuration style information
func (s *service) GenerateToken(keyId string, metadata map[string]string, body *vagrant_server.Token) (string, error) {
	key, err := s.state.HMACKeyCreateIfNotExist(keyId, hmacKeySize)
	if err != nil {
		return "", err
	}

	bodyData, err := proto.Marshal(body)
	if err != nil {
		return "", err
	}

	h, err := blake2b.New256(key.Key)
	if err != nil {
		return "", err
	}

	h.Write(bodyData)

	var tt vagrant_server.TokenTransport
	tt.Body = bodyData
	tt.KeyId = keyId
	tt.Metadata = metadata
	tt.Signature = h.Sum(nil)

	ttData, err := proto.Marshal(&tt)
	if err != nil {
		return "", err
	}

	var buf bytes.Buffer
	buf.WriteString(tokenMagic)
	buf.Write(ttData)

	return base58.Encode(buf.Bytes()), nil
}

// Create a new login token.
// keyId controls which key is used to sign the key (key values are generated lazily).
// metadata is attached to the token transport as configuration style information
func (s *service) NewLoginToken(
	keyId string,
	metadata map[string]string,
	entrypoint *vagrant_server.Token_Entrypoint,
) (string, error) {
	var body vagrant_server.Token
	body.Login = true
	body.User = DefaultUser
	body.TokenId = make([]byte, 16)
	body.Entrypoint = entrypoint

	_, err := io.ReadFull(rand.Reader, body.TokenId)
	if err != nil {
		return "", err
	}

	return s.GenerateToken(keyId, metadata, &body)
}

// Create a new login token. This is just a gRPC wrapper around NewLoginToken.
func (s *service) GenerateLoginToken(ctx context.Context, _ *emptypb.Empty) (*vagrant_server.NewTokenResponse, error) {
	token, err := s.NewLoginToken(DefaultKeyId, nil, nil)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.NewTokenResponse{Token: token}, nil
}

// Create a new invite token. The duration controls for how long the invite token is valid.
// keyId controls which key is used to sign the key (key values are generated lazily).
// metadata is attached to the token transport as configuration style information
func (s *service) NewInviteToken(
	duration time.Duration,
	keyId string,
	metadata map[string]string,
	entrypoint *vagrant_server.Token_Entrypoint,
) (string, error) {
	var body vagrant_server.Token
	body.Invite = true
	body.TokenId = make([]byte, 16)
	body.Entrypoint = entrypoint

	now := time.Now().UTC().Add(duration)
	body.ValidUntil = &timestamppb.Timestamp{
		Seconds: now.Unix(),
		Nanos:   int32(now.Nanosecond()),
	}

	_, err := io.ReadFull(rand.Reader, body.TokenId)
	if err != nil {
		return "", err
	}

	return s.GenerateToken(keyId, metadata, &body)
}

// Create a new invite token. This is just a gRPC wrapper around NewInviteToken.
func (s *service) GenerateInviteToken(ctx context.Context, req *vagrant_server.InviteTokenRequest) (*vagrant_server.NewTokenResponse, error) {
	dur, err := time.ParseDuration(req.Duration)
	if err != nil {
		return nil, err
	}

	token, err := s.NewInviteToken(dur, DefaultKeyId, nil, req.Entrypoint)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.NewTokenResponse{Token: token}, nil
}

// Given an invite token, validate it and return a login token
func (s *service) ExchangeInvite(keyId, invite string) (string, error) {
	tt, body, err := s.DecodeToken(invite)
	if err != nil {
		return "", err
	}

	if !body.Invite {
		return "", errors.Wrapf(ErrInvalidToken, "not an invite token")
	}

	return s.NewLoginToken(keyId, tt.Metadata, body.Entrypoint)
}

// Given an invite token, validate it and return a login token. This is a gRPC wrapper around ExchangeInvite.
func (s *service) ConvertInviteToken(ctx context.Context, req *vagrant_server.ConvertInviteTokenRequest) (*vagrant_server.NewTokenResponse, error) {
	token, err := s.ExchangeInvite(DefaultKeyId, req.Token)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.NewTokenResponse{Token: token}, nil
}

func (s *service) BootstrapToken(ctx context.Context, req *emptypb.Empty) (*vagrant_server.NewTokenResponse, error) {
	if !s.state.HMACKeyEmpty() {
		return nil, status.Errorf(codes.PermissionDenied, "server is already bootstrapped")
	}

	token, err := s.NewLoginToken(DefaultKeyId, nil, nil)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.NewTokenResponse{Token: token}, nil
}

func (s *service) Bootstrapped() bool {
	return !s.state.HMACKeyEmpty()
}
