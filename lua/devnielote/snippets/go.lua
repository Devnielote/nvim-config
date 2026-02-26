local ls = require("luasnip")
local parse = ls.parser.parse_snippet

-- Hace que todos los "$" del texto se conviertan en "\$"
-- para que LuaSnip los trate como literales
local function lit(text)
  return (text:gsub("%$", "\\$"))
end

return {
  ---------------------------------------------------------------------------
  -- 1) HANDLERS
  ---------------------------------------------------------------------------
  parse("gomod_handlers", lit([[
package handlers

import (
   "erp-manager/internal/modules/$module$/mapper"
   "erp-manager/internal/modules/$module$/dto/request"
   "erp-manager/internal/modules/$module$/dto/response"
   "erp-manager/internal/modules/$module$/services"
   "erp-manager/pkg/utils"
   "github.com/labstack/echo/v4"
   "net/http"
   "strings"
)

type $Struct$Handler struct {
   service *services.$Struct$Service
}

func New$Struct$Handler(service *services.$Struct$Service) *$Struct$Handler {
   return &$Struct$Handler{service: service}
}

// Create crea un nuevo registro
// @Summary Crea un nuevo registro de tipo "$Struct$"
// @Tags $Struct$
// @Accept json
// @Produce json
// @Param request body request.Create$Struct$Request true "Datos del registro"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$ [post]
func (h *$Struct$Handler) Create(c echo.Context) error {
   var req request.Create$Struct$Request
   if err := c.Bind(&req); err != nil {
      return utils.ErrorMessage(c, "InvalidPayload: "+err.Error())
   }

   if !utils.HasAnyField(&req) {
      return utils.ErrorMessage(c, "EmptyUpdatePayload")
   }

   if ok, errMap := utils.ValidateStruct(&req); !ok {
      return utils.FailMessage(c, "ValidationError: ", errMap)
   }

   // Enviar el request al servicio para procesarlo
   created, err := h.service.Create(c.Request().Context(), req)
   if err != nil {
      return utils.ErrorMessage(c, "Create$Struct$Failed: "+err.Error())
   }

   return utils.SuccessMessage(c, "$Struct$Created", created)
}

// GetByID permite obtener un registro a través de su ID
// @Summary Obtener el registro por ID
// @Description Retorna un registro con su información básica.
// @Tags $Struct$
// @Accept json
// @Produce json
// @Param id path int true "ID del registro"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/{id} [get]
func (h *$Struct$Handler) GetByID(c echo.Context) error {

   // ID del registro a encontrar
   id, err := utils.ParseUint64Param(c, "id")
   if err != nil {
      return utils.ErrorMessage(c, "InvalidID "+err.Error())
   }

   // Obtiene los datos a través de su identificador
   data, err := h.service.GetByID(c.Request().Context(), id)
   if err != nil {
      return utils.ErrorMessage(c, "$Struct$NotFound")
   }

   res := mappers.Map$Struct$ToFullResponse(data)

   return utils.SuccessMessage(c, "$Struct$Found", res)
}

// Update permite actualizar la información
// @Summary Actualizar el registro
// @Tags $Struct$
// @Accept json
// @Produce json
// @Param id path int true "ID del registro"
// @Param request body request.Update$Struct$Request true "Datos actualizados"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/{id} [put]
func (h *$Struct$Handler) Update(c echo.Context) error {

   id, err := utils.ParseUint64Param(c, "id")
   if err != nil {
      return utils.ErrorMessage(c, "InvalidID")
   }

   // DTO
   var req request.Update$Struct$Request
   if err := c.Bind(&req); err != nil {
      return utils.ErrorMessage(c, "InvalidPayload: "+err.Error())
   }

   // Valida si tiene registros el request
   if !utils.HasAnyField(&req) {
      return utils.ErrorMessage(c, "EmptyUpdatePayload")
   }

   data, err := h.service.Update(c.Request().Context(), id, &req)
   if err != nil {
      return utils.ErrorMessage(c, "Update$Struct$Failed: "+err.Error())
   }

   // Generar el mapper correspondiente
   res := mappers.Map$Struct$ToFullResponse(data)

   return utils.SuccessMessage(c, "$Struct$Updated", res)

}

// Delete permite eliminar un registro
// @Summary Elimina un registro
// @Tags $Struct$
// @Produce json
// @Param id path int true "ID del registro"
// @Success 200 {object} utils.APIResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/{id} [delete]
func (h *$Struct$Handler) Delete(c echo.Context) error {
   id, err := utils.ParseUint64Param(c, "id")
   if err != nil {
      return utils.ErrorMessage(c, "InvalidID")
   }
   if err := h.service.Delete(c.Request().Context(), id); err != nil {
      return utils.ErrorMessage(c, "Delete$Struct$Failed")
   }
   return utils.SuccessMessage(c, "$Struct$Deleted", nil)
}

// GetAll lista registros con filtros y paginación
// @Summary Listar registros
// @Tags $Struct$
// @Produce json
// @Param q query string false "Búsqueda"
// @Param active query bool false "Filtrar por activos"
// @Param order_by query string false "Campo de ordenamiento"
// @Param page query int false "Número de página"
// @Param limit query int false "Límite de registros"
// @Success 200 {object} utils.ListResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$ [get]
func (h *$Struct$Handler) GetAll(c echo.Context) error {

   // Si el parámetro se establece, será utilizado en la consulta, si no, se asume como verdadero
   // Esto evita tener que establecerlo si se solicitan los registros activos
   active := utils.GetOptionalBoolParm(c, "active")

   // q representa la query de búsqueda, está abierta a buscar en N campos
   // q=19, q=Nombre
   search := c.QueryParam("q")

   // Parámetros de paginación
   limit, offset, page := utils.GetPaginateParms(c)

   // Permite utilizar solo los campos definidos en la respuesta de DTO, el request
   // no aplica, ya que, no existe una estructura de entrada, solo parámetros
   allowedFields := utils.GetAllowedFieldsFromDTO(response.Get$Struct$ListResponse{})

   // Procesar ordenamiento
   orderParam := c.QueryParam("order_by")
   orderBy, err := utils.ParseOrderBy(orderParam, allowedFields)
   if err != nil {
      return utils.ErrorMessage(c, "InvalidOrderBy: "+err.Error())
   }

   // Obtener datos paginados desde servicio
   data, total, err := h.service.GetPaginatedList(c.Request().Context(), search, active, limit, offset, orderBy)
   if err != nil {
      return utils.ErrorMessage(c, "ReadFailed: "+err.Error())
   }

   // Validar si la página existe
   err = utils.IsPageInRange(c, page, total, limit)
   if err != nil {
      return utils.ErrorMessage(c, "PageOutOfRange: "+err.Error())
   }

   // Llenando el DTO
   result := mappers.Map$Struct$ToListResponse(data)

   // Respuesta con los parámetros indicados:
   // c        -> Contexto
   // messageKey  -> El mensaje que se usará en la traducción en el paquete i18n
   // dto         -> La lista de registros a mostrar
   // model       -> El modelo que servirá para saber cómo ordenar las cabeceras en utils.GetFieldOrder
   // total       -> Total de registros de la consulta
   return utils.ListSuccessMessage(c, "ReadSuccess", result, "$module$", total)

}

// ExportToZip permite exportar registros en un archivo comprimido
// @Summary Exportar plantillas a ZIP
// @Tags $Struct$
// @Produce application/zip
// @Param ids query string false "IDs separados por coma"
// @Param q query string false "Búsqueda"
// @Param all query bool false "Exportar todo"
// @Success 200 {file} response.$Struct$ExportRow
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/export [get]
func (h *$Struct$Handler) ExportToZip(c echo.Context) error {
   idsParam := c.QueryParam("ids")
   all := utils.GetOptionalBoolParm(c, "all")
   q := c.QueryParam("q")

   var ids []uint64
   if idsParam != "" {
      idStrings := strings.Split(idsParam, ",")
      for _, idStr := range idStrings {
         id, err := utils.ParseStringToUint64(strings.TrimSpace(idStr))
         if err != nil {
            return utils.ErrorMessage(c, "InvalidIDParam: "+err.Error())
         }
         ids = append(ids, id)
      }
   }

   zipData, err := h.service.ExportToZip(c.Request().Context(), ids, *all, q)

   if err != nil {
      if err.Error() == "NotFound" {
         return utils.NotFound(c, "NotFound")
      }

      return utils.ErrorMessage(c, "ExportFailed: "+err.Error())
   }

   c.Response().Header().Set(echo.HeaderContentDisposition, `attachment; filename="$module$_export.zip"`)
   c.Response().Header().Set(echo.HeaderContentType, "application/zip")
   return c.Blob(http.StatusOK, "application/zip", zipData)
}

// GetNameList Devuelve la lista de registros (ID + Name)
// @Summary Devuelve la lista de registros (ID + Name)
// @Description Devuelve la lista de registros para ser usados en dropdowns
// @Tags $Struct$
// @Produce json
// @Success 200 {file} response.Get$Struct$NameListResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/names-list [get]
func (h *$Struct$Handler) GetNameList(c echo.Context) error {
   active := utils.GetOptionalBoolParm(c, c.QueryParam("active")) // retorna *bool

   data, err := h.service.GetNameList(c.Request().Context(), active)
   if err != nil {
      return utils.ErrorMessage(c, "Failed: "+err.Error())
   }
   result := mappers.Map$Struct$ToFullNameList(data)

   return utils.SuccessMessage(c, "Success", result)
}

// GetDropdownNameList Devuelve la lista de registros (ID + Name)
// @Summary Devuelve la lista de registros (ID + Name)
// @Description Devuelve la lista de registros para ser usados en dropdowns
// @Tags $Struct$
// @Produce json
// @Param q query string false "Búsqueda"
// @Success 200 {file} response.Get$Struct$NameListResponse
// @Failure 400 {object} utils.APIResponse
// @Security BearerAuth
// @Router /api/v1/$module$/names [get]
func (h *$Struct$Handler) GetDropdownNameList(c echo.Context) error {

   name := c.QueryParam("q")

   data, err := h.service.GetDropdownNameList(c.Request().Context(), name)
   if err != nil {
      return utils.ErrorMessage(c, "Failed: "+err.Error())
   }
   result := mappers.Map$Struct$ToFullNameList(data)

   return c.JSON(http.StatusOK, result)
}
]])),

  ---------------------------------------------------------------------------
  -- 2) MAPPERS
  ---------------------------------------------------------------------------
  parse("gomod_mappers", lit([[
package mappers

import (
        "erp-manager/internal/modules/$module$/dto/request"
        "erp-manager/internal/modules/$module$/dto/response"
        attachmentresponse "erp-manager/internal/modules/attachment/dto/response"
        "erp-manager/internal/modules/$module$/models"
)

/*
Conversión              Nombre sugerido
CreateRequest   → Model                     MapCreate<Struct>RequestToModel
Model                   → CreateResponse                Map<Struct>ToCreateResponse

Si un valor bool puntero es nil, usar PtrToBool, ejemplo:
IsCompany:       utils.PtrToBool(data.IsCompany),

Definir campos nested:
response:
Type mode.Type
mapper:
Type: response.TemplateTypeResponse{
                        ID:   t.Type.ID,
                        Name: t.Type.Name,
                }
*/

// MapCreate$Struct$RequestToModel convierte el Create$Struct$Request en un modelo $Struct$
func MapCreate$Struct$RequestToModel(request request.Create$Struct$Request) *models.$Struct$ {
        return &models.$Struct${
                Name:   request.Name,
        }
}

// Map$Struct$ToListResponse convierte los registros de $Struct$ a Get$Struct$ListResponse (vista lista)
func Map$Struct$ToListResponse(model []models.$Struct$) []response.Get$Struct$ListResponse {
        // Agrega al DTO la respuesta para visualizar la lista
        var result []response.Get$Struct$ListResponse
        for _, data := range model {
                result = append(result, response.Get$Struct$ListResponse{
                        ID:                  data.ID,
                        Active:              data.Active,
                        Name:                data.Name,
                        // No mapear ID´s de modelos relacionados
                })
        }
        return result
}

// Map$Struct$ToFullResponse devuelve un registro de forma unitaria
func Map$Struct$ToFullResponse(model *models.$Struct$) response.Get$Struct$FullResponse {

        var attachments []attachmentresponse.GetAttachmentResponse

        for _, a := range model.Attachments {
                attachments = append(attachments, attachmentresponse.GetAttachmentResponse{
                        ID:         a.ID,
                        Model:      a.Model,
                        RecordID:   a.RecordID,
                        FileName:   a.FileName,
                        Bucket:     a.Bucket,
                        MimeType:   a.MimeType,
                        Size:       a.Size,
                        ObjectKey:  a.ObjectKey,
                        StorageURL: a.StorageURL,
                        UUID:       a.UUID.String(),
                        UsedFor:    a.UsedFor,
                })
        }

        return response.Get$Struct$FullResponse{
                ID:                  model.ID,
                Active:              model.Active,
                Name:                model.Name,
                // Mapear ID´s de modelos relacionados
        }
}

// Map$Struct$ToExportRows convierte un slice de $Struct$ a un slice listo para exportación
func Map$Struct$ToExportRows(model []models.$Struct$) []response.$Struct$ExportRow {
        var exportRows []response.$Struct$ExportRow

        for _, data := range model {
                exportRows = append(exportRows, response.$Struct$ExportRow{
                        ID:                  data.ID,
                        Name:                data.Name,
                        // No mapear ID´s de modelos relacionados
                })
        }

        return exportRows
}

// Map$Struct$ToFullNameList convierte una lista de modelos $Struct$ a su representación reducida de ID + Name.
func Map$Struct$ToFullNameList(model []models.$Struct$) []response.Get$Struct$NameListResponse {
        result := make([]response.Get$Struct$NameListResponse, 0, len(model))
        for _, data := range model {
                result = append(result, response.Get$Struct$NameListResponse{
                        ID:   data.ID,
                        Name: data.Name,
                })
        }
        return result
}
]])),

  ---------------------------------------------------------------------------
  -- 3) REPOSITORIES
  ---------------------------------------------------------------------------
  parse("gomod_repo", lit([[
package repositories

import (
   "context"
   "erp-manager/internal/modules/base/scopes"
   "erp-manager/internal/modules/$module$/mapper"
   "erp-manager/internal/modules/$module$/models"
   "erp-manager/internal/modules/infrastructure/devices/views"

   attachment "erp-manager/internal/modules/attachment/models"

   "erp-manager/pkg/utils"
   "errors"
   "gorm.io/gorm"
   "strings"
)

type $Struct$Repository interface {
   Create(ctx context.Context, model *models.$Struct$) error
   GetByID(ctx context.Context, id uint64) (*models.$Struct$, error)
   FindViewByID(ctx context.Context, id uint64) (*views.$ViewName$, error)
   Update(ctx context.Context, model *models.$Struct$) error
   Delete(ctx context.Context, id uint64) error
   GetAll(ctx context.Context, active *bool) ([]models.$Struct$, error)
   Search(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error)
   GetPaginatedList(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error)
   ExportToZip(ctx context.Context, ids []uint64, all bool, q string) ([]byte, error)
   FindByName(ctx context.Context, name string) (*models.$Struct$, error)
   GetNameList(ctx context.Context, active *bool) ([]models.$Struct$, error)
   GetDropdownNameList(ctx context.Context, name string) ([]models.$Struct$, error)
}

type $var$Repository struct {
   db *gorm.DB
}

func New$Struct$Repository(db *gorm.DB) $Struct$Repository {
   return &$var$Repository{db: db}
}

// FindByName busca un registro a partir de su nombre
func (r *$var$Repository) FindByName(ctx context.Context, name string) (*models.$Struct$, error) {
   var model models.$Struct$
   err := r.db.WithContext(ctx).Scopes(
      scopes.NewActive(nil),
   ).Where("name = ?", name).First(&model).Error
   if err != nil {
      return nil, err
   }
   return &model, nil
}

// Create crea un registro en el modelo
func (r *$var$Repository) Create(ctx context.Context, model *models.$Struct$) error {
   // Crear el registro
   if err := r.db.WithContext(ctx).Create(model).Error; err != nil {
      return err
   }

   // Aplicar preload y recuperar el modelo completo actualizado
   if err := apply$Struct$Preloads(r.db.WithContext(ctx)).
      First(model, model.ID).Error; err != nil {
      return err
   }

   return nil
}


// GetByID devuelve un registro a partir de su ID
func (r *$var$Repository) GetByID(ctx context.Context, id uint64) (*models.$Struct$, error) {
   var model models.$Struct$

   err := apply$Struct$Preloads(
      r.db.WithContext(ctx),
   ).First(&model, id).Error
   if err != nil {
      return nil, err
   }

   // Carga los attachments manualmente
   var attachments []attachment.Attachment
   err = r.db.WithContext(ctx).
      Where("record_id = ? AND model = ?", model.ID, "warehouse.product").
      Find(&attachments).Error
   if err != nil {
      return nil, err
   }
   model.Attachments = attachments

   return &model, nil

}

// FindViewByID devuelve un registro a partir de su ID
func (r *$var$Repository) FindViewByID(ctx context.Context, id uint64) (*views.$ViewName$, error) {
   var view views.$ViewName$
   if err := r.db.WithContext(ctx).
      Table("$var$_list_view").
      Where("id = ?", id).
      First(&view).Error; err != nil {
      return nil, err
   }
   return &view, nil

}

// GetAll devuelve una lista de registros sin paginación
func (r *$var$Repository) GetAll(ctx context.Context, active *bool) ([]models.$Struct$, error) {
   var list []models.$Struct$
   err := r.db.WithContext(ctx).Scopes(
      scopes.NewActive(active),
   ).Order("name ASC").Find(&list).Error
   return list, err
}

// Search busca registros a partir su nombre, idealmente, usar GetPaginatedList para obrecer más dinamismo
func (r *$var$Repository) Search(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error) {
   var model []views.$ViewName$
   var total int
   search = "%" + strings.ToLower(search) + "%"

   err := r.db.WithContext(ctx).
      Scopes(scopes.NewActive(active)).
      Where("LOWER(name) ILIKE ?", search).
      Order(*orderBy).
      Limit(limit).
      Offset(offset).
      Find(&model).Error

   if err != nil {
      return nil, 0, err
   }

   total = len(model)

   return model, total, err
}

// GetPaginatedList devuelve una lista de registros paginada
func (r *$var$Repository) GetPaginatedList(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error) {

   var (
      listViews []views.$ViewName$
      total int64
   )

   // Consulta base
   query := r.db.WithContext(ctx).Model(&views.$ViewName${}).Scopes(scopes.NewActive(active))

   // Obtención de las columnas del modelo para la búsqueda dinámica
   modelFields := utils.GetDBColumnNames(views.$ViewName${})

   // Filtro por búsqueda
   query = utils.ApplyDynamicSearch(query, search, modelFields)

   // Ordenamiento, siempre será por NAME por default
   if orderBy != nil && *orderBy != "" {
      query = query.Order(*orderBy)
   } else {
      query = query.Order("name ASC")
   }

   // Total de registros (sin paginación)
   if err := query.Session(&gorm.Session{}).Count(&total).Error; err != nil {
      return nil, 0, err
   }

   // Aplicar paginación
   if query.Limit(limit).Offset(offset).Find(&listViews).Error != nil {
      return nil, 0, nil
   }

   return listViews, int(total), nil
}

// Update actualiza los campos de un registro
func (r *$var$Repository) Update(ctx context.Context, model *models.$Struct$) error {

   // Convierte el modelo a un Map para indicar explícitamente los campos a actualizar
   updates, err := utils.ModelToMap(model)
   if err != nil {
      return err
   }

   // Actualiza el registro
   if r.db.WithContext(ctx).Model(&models.$Struct${}).Where("id = ?", model.ID).Updates(updates).Error != nil {
      return errors.New("error while updating template")
   }

   // Obtiene el registro actualizado
   updated, err := r.GetByID(ctx, model.ID)
   if err != nil {
      return err
   }

    // Actualiza el puntero original
   *model = *updated

   return err

}

// Delete elimina un registro a través de su id
func (r *$var$Repository) Delete(ctx context.Context, id uint64) error {
   return r.db.WithContext(ctx).Delete(&models.$Struct${}, id).Error
}

// ExportToZip exporta los registros asociados o todos a un archivo descargable .zip
func (r *$var$Repository) ExportToZip(ctx context.Context, ids []uint64, all bool, q string) ([]byte, error) {
   var model []models.$Struct$

   query := r.db.WithContext(ctx).Model(&models.$Struct${}).Order("name ASC")

   // Si se especifican IDs
   if len(ids) > 0 {
      query = query.Where("id IN ?", ids)
   }

   // Si se solicita "all" con búsqueda por texto
   if strings.TrimSpace(q) != "" {
      q = "%" + strings.ToLower(q) + "%"

      // Obtención de las columnas del modelo para la búsqueda dinámica
      modelFields := utils.GetDBColumnNames(models.$Struct${})

      // Filtro por búsqueda
      query = utils.ApplyDynamicSearch(query, q, modelFields)
   }

   // Ejecutar la consulta, igual aplica a all
   if err := apply$Struct$Preloads(query).
      Find(&model).Error; err != nil {
      return nil, err
   }

   if len(model) == 0 {
      return nil, errors.New("NotFound")
   }

   // Preparar los campos en orden específico
   //fieldOrder := utils.GetFieldOrder("company")

   // Prepara los rows para ser aceptados por StructToMap2
   rows := mappers.Map$Struct$ToExportRows(model)

   // Mapear los resultados
   data, headers := utils.StructsToMap2(rows)

   // Generar el archivo Excel
   excelData, err := utils.GenerateExcelFromData2("$Struct$", headers, data)
   if err != nil {
      return nil, err
   }

   // Comprimir a ZIP
   zipData, err := utils.CompressToZip("$Struct$.xlsx", excelData)
   if err != nil {
      return nil, err
   }

   return zipData, nil
}

// GetNameList devuelve el valor del campo name del registro
func (r *$var$Repository) GetNameList(ctx context.Context, active *bool) ([]models.$Struct$, error) {
   var $var$ []models.$Struct$
   err := r.db.WithContext(ctx).
      Select("id", "name").
      Model(&models.$Struct${}).
      Scopes(scopes.NewActive(active)).
      Order("name ASC").
      Find(&$var$).Error

   return $var$, err
}

// GetDropdownNameList devuelve el valor del campo name del registro
func (r *$var$Repository) GetDropdownNameList(ctx context.Context, name string) ([]models.$Struct$, error) {
   var $var$ []models.$Struct$

   name = "%" + strings.ToLower(name) + "%"

   err := r.db.WithContext(ctx).
      Select("id", "name").
      Model(&models.$Struct${}).
      Scopes(scopes.NewActive(nil)).
      Where("name ILIKE ?", name).
      Order("name ASC").
      Find(&$var$).Error

   return $var$, err
}

// apply$Struct$Preloads Aplica los preloads para el modelo
func apply$Struct$Preloads(query *gorm.DB) *gorm.DB {
   return query
}
]])),

  ---------------------------------------------------------------------------
  -- 4) REQUEST DTOs
  ---------------------------------------------------------------------------
  parse("gomod_request", lit([[
package request

// swagger:model Create$Struct$Request
// Datos enviados para crear un registro
// Create$Struct$Request representa los datos requeridos para crear un nuevo registro.
type Create$Struct$Request struct {
	// Nombre completo del objet $Struct$
	Name string `json:"name" validate:"required"`
}

// swagger:model Update$Struct$Request
// Datos devueltos para un registro específico
type Update$Struct$Request struct {
	// Activa o desactiva un registro
	Active *bool  `json:"active"`
	// Nombre completo del objet $Struct$
	Name   *string `json:"name"`
}
]])),

---------------------------------------------------------------------------
-- 5) RESPONSE DTOs
---------------------------------------------------------------------------
  parse("gomod_response", lit([[
package response

import (
	"erp-manager/internal/modules/attachment/dto/response"
)
/*
Listas          Get<Model>ListResponse    Lista paginada o completa de registros
Registro único  Get<Model>FullResponse    Registro único con modelos asociados

Respuestas asociadas a una lista de modelos:
Roles           []RoleResponse            json:"roles"             // Roles y permisos del usuario
*/

// swagger:model Get$Struct$FullResponse
// Get$Struct$FullResponse devuelve el registro, solo envía IDs de modelos relacionados, definir <Field>Name y <Field>ID
type Get$Struct$FullResponse struct {
	// ID del registro
	ID     uint64 `json:"id"`
	// Activa o desactiva un registro
	Active *bool  `json:"active"`
	// Nombre completo del objeto $Struct$
	Name   string `json:"name"`

	// Incluir attachments
	Attachments []response.GetAttachmentResponse `json:"attachments"`
}

// Get$Struct$ListResponse es opcional, si la respuesta contiene modelos relacinados,
// la mejor decisión es devolver un objeto $LStruct$_list_view (SQL View) de la base de datos
// swagger:model Get$Struct$ListResponse
// Get$Struct$ListResponse devuelve el listado de registros, muestra <Field>Name, no IDs de modelos relacionados
type Get$Struct$ListResponse struct {
	// ID del registro
	ID     uint64 `json:"id"`
	// Activa o desactiva un registro
	Active *bool  `json:"active"`
	// Nombre completo del objeto $Struct$
	Name   string `json:"name"`
}

// swagger:model Get$Struct$NameListResponse
// Get$Struct$NameListResponse devuelve el id y nombre del registro
type Get$Struct$NameListResponse struct {
	// ID del registro
	ID   uint64 `json:"id"`
	// Nombre del objeto $Struct$
	Name string `json:"name"`
}

// swagger:model $Struct$ExportRow
// $Struct$ExportRow devuelve el listado de registros
type $Struct$ExportRow struct {
	// ID del registro
	ID   uint64 `json:"id"`
	// Nombre completo del objeto $Struct$
	Name string `json:"name"`
	// No enviar IDs de modelos relacionados, muestra <Field>Name, no IDs de modelos relacionados
}
]])),

  ---------------------------------------------------------------------------
  -- 6) SERVICES
  ---------------------------------------------------------------------------
  parse("gomod_services", lit([[
package services

import (
   "erp-manager/internal/modules/$module$/dto/request"
   "erp-manager/internal/modules/$module$/dto/response"
   "erp-manager/internal/modules/$module$/mapper"
   "erp-manager/internal/modules/$module$/models"
   "erp-manager/internal/modules/$module$/views"
   "erp-manager/pkg/utils"

   auditLogService "erp-manager/internal/modules/auditlog/services"
   repo "erp-manager/internal/modules/$module$/repositories"
   messagingService "erp-manager/internal/modules/messaging/services"
   userhelper "erp-manager/internal/modules/user/helpers"

   "errors"

   "golang.org/x/net/context"
)

type $Struct$Service struct {
   repo repo.$Struct$Repository
   messagingTemplateService messagingService.MessagingTemplateService
   audit *auditLogService.AuditLogService
}

func New$Struct$Service(
    repo repo.$Struct$Repository,
    messagingTemplateService messagingService.MessagingTemplateService,
    audit *auditLogService.AuditLogService) *$Struct$Service {
   return &$Struct$Service{
       repo: repo,
       messagingTemplateService: messagingTemplateService,
       audit: audit,
       }
}

// Create crea un nuevo registro de $Struct$
func (s *$Struct$Service) Create(ctx context.Context, dto request.Create$Struct$Request) (response.Get$Struct$FullResponse, error) {

   exist, _ := s.repo.FindByName(ctx, dto.Name)
   if exist != nil {
      return response.Get$Struct$FullResponse{}, errors.New("$module$ already exist")
   }

   /* Si aplica para datos tipo JSON, hay que establecerlos manualmente
   if company.Content == nil {
      company.Content = datatypes.JSON("{}")
   }

   if company.Variables == nil {
      company.Variables = datatypes.JSON("[]")
   }
   */

   // Llenado del modelo
   $module$ := mappers.MapCreate$Struct$RequestToModel(dto)

   // Envío al repositorio
   if err := s.repo.Create(ctx, $module$); err != nil {
      return response.Get$Struct$FullResponse{}, err
   }

    // Registro de Auditoría
    user, ok := userhelper.GetUserFromContext(ctx)
    if ok {
        go s.audit.RegisterCreate(context.Background(), $module$, user)
    }

   // Búsca el registro y devuelve la vista completa
   view, err := s.repo.FindViewByID(ctx, $module$.ID)
   if err != nil {
      return response.Get$module$FullResponse{}, err
   }

   // Mapper hacia response
   return mapper.Map$Struct$ToFullResponse(view), nil
}

// GetByID devuelve un $module$ a través de su ID
func (s *$Struct$Service) GetByID(ctx context.Context, id uint64) (*response.Get$Struct$FullResponse, error) {

   // Consultar el registro
   view, err := s.repo.FindViewByID(ctx, id)
   if err != nil {
      return nil, err
   }

   data := mapper.Map$Struct$ToFullResponse(view)
   return &data, nil

}

// Update actualiza un $module$
func (s *$Struct$Service) Update(ctx context.Context, id uint64, dto *request.Update$Struct$Request) (*response.Get$Struct$FullResponse, error) {

    $module$ToUpdate, err := s.repo.GetByID(ctx, id)
    if err != nil {
        return nil, errors.New("NotFound")
    }

    beforeState, err := utils.InterfaceToMap($module$ToUpdate)
    if err != nil {
        beforeState = nil
    }

    if err := utils.ApplyPatch($module$ToUpdate, dto); err != nil {
        return nil, errors.New("UpdatePatchFailed")
    }

    err = s.repo.Update(ctx, $module$ToUpdate)
   if err != nil {
      return nil, err
   }

    if beforeState != nil {
        user, ok := userhelper.GetUserFromContext(ctx)
        if ok {
            // Registro de Auditoría
            go s.audit.RegisterUpdate(context.Background(), beforeState, $module$ToUpdate, user.Name)
        }
    }

   view, err := s.repo.FindViewByID(ctx, $module$ToUpdate.ID)
   if err != nil {
      return nil, err
   }
   data := mapper.Map$Struct$ToFullResponse(view)

   return &data, nil
}

// Delete elimina un $module$
func (s *$Struct$Service) Delete(ctx context.Context, id uint64) error {
   return s.repo.Delete(ctx, id)
}

// GetPaginatedList obtiene una lista paginada de $module$
func (s *$Struct$Service) GetPaginatedList(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error) {
   return s.repo.GetPaginatedList(ctx, search, active, limit, offset, orderBy)
}

// Search busca un $module$
func (s *$Struct$Service) Search(ctx context.Context, search string, active *bool, limit int, offset int, orderBy *string) ([]views.$ViewName$, int, error) {
   return s.repo.Search(ctx, search, active, limit, offset, orderBy)
}

// ExportToZip exporta un listado en .zip
func (s *$Struct$Service) ExportToZip(ctx context.Context, ids []uint64, all bool, q string) ([]byte, error) {
   return s.repo.ExportToZip(ctx, ids, all, q)
}

// GetNameList devuelve una lista de nombres y ids
func (s *$Struct$Service) GetNameList(ctx context.Context, active *bool) ([]models.$Struct$, error) {
   data, err := s.repo.GetNameList(ctx, active)
   if err != nil {
      return nil, err
   }
   return data, nil
}

// GetDropdownNameList devuelve una lista de nombres por coincidencia
func (s *$Struct$Service) GetDropdownNameList(ctx context.Context, name string) ([]models.$Struct$, error) {
   data, err := s.repo.GetDropdownNameList(ctx, name)
   if err != nil {
      return nil, err
   }
   return data, nil
}

func (s *$Struct$Service) GetTemplateFields(ctx context.Context) ([]string, error) {
   var row views.$Struct$ListView
   t := reflect.TypeOf(row)
   var fields []string

   for i := 0; i < t.NumField(); i++ {
      jsonTag := t.Field(i).Tag.Get("gorm")
      if jsonTag == "" {
         continue
      }
      col := strings.Split(jsonTag, ":")
      if len(col) > 1 {
         fields = append(fields, fmt.Sprintf("{{%s}}", col[1]))
      }
   }

   return fields, nil
}
]])),

---------------------------------------------------------------------------
-- 7) MODELS
---------------------------------------------------------------------------
  parse("gomod_models", lit([[
package models

import (
    basemodel "erp-manager/internal/modules/base/models"
)

// $Struct$ representa el modelo principal de "$module$"
type $Struct$ struct {
    basemodel.BaseModel

    // Campos principales
    Name string `gorm:"column:name" json:"name"`

    // Si deseas agregar relaciones:
    // Attachments []attachment.Attachment `gorm:"foreignKey:RecordID;references:ID"`
}

// TableName define la tabla SQL real del modelo
func ($Struct$) TableName() string {
    return "$module$"
}
]])),
---------------------------------------------------------------------------
-- 8) VIEWS
---------------------------------------------------------------------------
parse("gomod_views", lit([[
package views

// $ViewName$ representa la vista SQL "$module$_list_view"
type $ViewName$ struct {
  ID uint64 `gorm:"column:id"`
  Active *bool `gorm:"column:active"`
  Name string `json:"name"`

  //Agregar aqui columnas faltantes
}

//TableName define el nombre de la vista SQL
func($Struct$) TableName() string {
  return "$module$_list_view"
}
]])),
}

