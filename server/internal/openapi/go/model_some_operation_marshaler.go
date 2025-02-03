package openapi

import (
	"encoding/json"
	"reflect"
)

func (p SomeOperation) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})

	val := reflect.ValueOf(p)
	typ := val.Type()

	for i := 0; i < val.NumField(); i++ {
		fieldValue := val.Field(i)
		fieldType := typ.Field(i)

		if fieldValue.CanInterface() && !isEmptyValueOneOf(fieldValue) {
			jsonTag := fieldType.Tag.Get("json")
			if jsonTag == "" {
				jsonTag = fieldType.Name
			}
			data[jsonTag] = fieldValue.Interface()
		}
	}

	return json.Marshal(data)
}

func isEmptyValueOneOf(v reflect.Value) bool {
	switch v.Kind() {
	case reflect.Struct:
		for i := 0; i < v.NumField(); i++ {
			if !isEmptyValuePrimitive(v.Field(i)) {
				return false
			}
		}
		return true
	}
	return isEmptyValuePrimitive(v)
}

func isEmptyValuePrimitive(v reflect.Value) bool {
	switch v.Kind() {
	case reflect.String:
		return v.String() == ""
	case reflect.Int, reflect.Int64:
		return v.Int() == 0
	case reflect.Bool:
		return v.Bool() == false
	case reflect.Ptr:
		return v.IsNil()
	case reflect.Slice:
		return v.Len() == 0
	case reflect.Map:
		return v.Len() == 0
	}
	return false
}
