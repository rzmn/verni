package images_mock

import (
	"verni/internal/repositories"
	"verni/internal/repositories/images"
)

type RepositoryMock struct {
	UploadImageBase64Impl func(base64 string) repositories.TransactionWithReturnValue[images.ImageId]
	GetImagesBase64Impl   func(ids []images.ImageId) ([]images.Image, error)
}

func (c *RepositoryMock) UploadImageBase64(base64 string) repositories.TransactionWithReturnValue[images.ImageId] {
	return c.UploadImageBase64Impl(base64)
}

func (c *RepositoryMock) GetImagesBase64(ids []images.ImageId) ([]images.Image, error) {
	return c.GetImagesBase64Impl(ids)
}
