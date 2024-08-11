package utils

import (
	"context"
)

func IsCanceled(ctx context.Context) bool {
	select {
	case <-ctx.Done():
		return true
	default:
		return false
	}
}

func IsProxied(ctx context.Context) bool {
	value := ctx.Value("is_proxy")
	if value == nil {
		return false
	}
	return value.(bool)
}
