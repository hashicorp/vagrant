package state

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"gorm.io/gorm"
)

type Component struct {
	gorm.Model

	Name       string         `gorm:"uniqueIndex:idx_stname"`
	ServerAddr string         `gorm:"uniqueIndex:idx_stname"`
	Type       component.Type `gorm:"uniqueIndex:idx_stname"`
	Runners    []*Runner      `gorm:"many2many:runner_components"`
}

func init() {
	models = append(models, &Component{})
}

func (c *Component) ToProtoRef() *vagrant_server.Ref_Component {
	if c == nil {
		return nil
	}

	return &vagrant_server.Ref_Component{
		Type: vagrant_server.Component_Type(c.Type),
		Name: c.Name,
	}
}

func (c *Component) ToProto() *vagrant_server.Component {
	if c == nil {
		return nil
	}

	return &vagrant_server.Component{
		Type:       vagrant_server.Component_Type(c.Type),
		Name:       c.Name,
		ServerAddr: c.ServerAddr,
	}
}

func (s *State) ComponentFromProto(p *vagrant_server.Component) (*Component, error) {
	var c Component

	result := s.db.First(&c, &Component{
		Name:       p.Name,
		ServerAddr: p.ServerAddr,
		Type:       component.Type(p.Type),
	})
	if result.Error == nil {
		return &c, nil
	}

	if result.Error == gorm.ErrRecordNotFound {
		c.Name = p.Name
		c.ServerAddr = p.ServerAddr
		c.Type = component.Type(p.Type)
		result = s.db.Save(&c)
		if result.Error != nil {
			return nil, result.Error
		}

		return &c, nil
	}

	return nil, result.Error
}
