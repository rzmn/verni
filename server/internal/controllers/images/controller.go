package images

import (
	"errors"
)

type ImageId string
type Image struct {
	Id     ImageId
	Base64 string
}

var (
	NoSuchImage = errors.New("no such image")
)

type Controller interface {
	GetImages(ids []ImageId) ([]Image, error)
}
