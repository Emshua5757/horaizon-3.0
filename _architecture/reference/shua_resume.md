# Repository Export

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\ai\tailor.go (232 lines)

#### TailorResume (Function)
```rust
// Lines 171-257 (87 LOC | Complexity 15) | used by 2 callers | [MutatesState, Io]
func TailorResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix
//  â³ Calls: OllamaResponse, OllamaRequest, TailorConfig, ResumeMatrix, Info, Error
//  â³ Called by: CompilePdfHandler, handleWsofflineCompile
```

#### workScore (Struct)
```rust
// Lines 83-86 (4 LOC | Complexity 1) | used by 1 callers
workScore struct
//  â³ Called by: FilterResume
```

#### TailorConfig (Struct)
```rust
// Lines 50-55 (6 LOC | Complexity 1) | used by 3 callers
TailorConfig struct
//  â³ Called by: TailorResume, FilterResume, DefaultTailorConfig
```

#### OllamaRequest (Struct)
```rust
// Lines 157-161 (5 LOC | Complexity 1) | used by 1 callers
OllamaRequest struct
//  â³ Called by: TailorResume
```

#### JaccardSimilarity (Function)
```rust
// Lines 32-47 (16 LOC | Complexity 6) | used by 2 callers | [Pure, Tested]
func JaccardSimilarity(setA, setB map[string]bool) float64
//  â³ Called by: TestJaccardSimilarity, FilterResume
```

#### DefaultTailorConfig (Function)
```rust
// Lines 58-65 (8 LOC | Complexity 1) | used by 3 callers | [Pure, Tested]
func DefaultTailorConfig() TailorConfig
//  â³ Calls: TailorConfig
//  â³ Called by: TestFilterResume, CompilePdfHandler, handleWsofflineCompile
```

#### projectScore (Struct)
```rust
// Lines 120-123 (4 LOC | Complexity 1) | used by 1 callers
projectScore struct
//  â³ Called by: FilterResume
```

#### Tokenize (Function)
```rust
// Lines 19-29 (11 LOC | Complexity 3) | used by 2 callers | [MutatesState, Tested]
func Tokenize(text string) map[string]bool
//  â³ Called by: TestTokenize, FilterResume
```

#### FilterResume (Function)
```rust
// Lines 68-154 (87 LOC | Complexity 14) | used by 3 callers | [MutatesState, Tested]
func FilterResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix
//  â³ Calls: projectScore, workScore, TailorConfig, ResumeMatrix, JaccardSimilarity, Tokenize
//  â³ Called by: TestFilterResume, CompilePdfHandler, handleWsofflineCompile
```

#### OllamaResponse (Struct)
```rust
// Lines 164-167 (4 LOC | Complexity 1) | used by 1 callers
OllamaResponse struct
//  â³ Called by: TailorResume
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\db\db.go (132 lines)

#### seedDatabase (Function)
```rust
// Lines 88-154 (67 LOC | Complexity 12) | used by 1 callers | [MutatesState, Io]
func seedDatabase() error
//  â³ Calls: Info
//  â³ Called by: InitDB
```

#### runMigrations (Function)
```rust
// Lines 54-86 (33 LOC | Complexity 3) | used by 1 callers | [Pure]
func runMigrations() error
//  â³ Called by: InitDB
```

#### InitDB (Function)
```rust
// Lines 21-52 (32 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io]
func InitDB(dbPath string) error
//  â³ Calls: Info, seedDatabase, runMigrations
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\logger\logger.go (116 lines)

#### init (Function)
```rust
// Lines 34-39 (6 LOC | Complexity 1) | used by 0 callers | [Async, Pure, PotentialDeadCode]
func init()
//  â³ Calls: logWorker
```

#### GetDroppedCount (Function)
```rust
// Lines 152-154 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
func GetDroppedCount() uint64
```

#### Error (Function)
```rust
// Lines 143-149 (7 LOC | Complexity 2) | used by 14 callers | [MutatesState, Tested, CorePrimitive]
func Error(subsystem, msg string, err error, telemetry map[string]interface{})
//  â³ Calls: submitLog
//  â³ Called by: TailorResume, CompileTypst, ListCompiledHandler, GetTemplatesHandler, saveCompilationToHistory, CompilePdfHandler, UpdateMatrixHandler, GetMatrixHandler, sendResponse, main, handleWsofflineCompile, assembleScreen, handleRpcCall, HandleWebSocket
```

#### resolveLogLevel (Function)
```rust
// Lines 96-111 (16 LOC | Complexity 6) | used by 1 callers | [Pure]
func resolveLogLevel(level string) uint8
//  â³ Called by: submitLog
```

#### LogEntry (Struct)
```rust
// Lines 15-23 (9 LOC | Complexity 1) | used by 1 callers
LogEntry struct
//  â³ Called by: submitLog
```

#### logWorker (Function)
```rust
// Lines 42-93 (52 LOC | Complexity 6) | used by 1 callers | [MutatesState, Io]
func logWorker()
//  â³ Called by: init
```

#### submitLog (Function)
```rust
// Lines 114-130 (17 LOC | Complexity 2) | used by 3 callers | [Async, Pure]
func submitLog(levelStr, subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: LogEntry, resolveLogLevel
//  â³ Called by: Error, Info, Debug
```

#### Info (Function)
```rust
// Lines 138-140 (3 LOC | Complexity 1) | used by 10 callers | [Pure]
func Info(subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: submitLog
//  â³ Called by: TailorResume, CompileTypst, saveCompilationToHistory, UpdateMatrixHandler, main, seedDatabase, InitDB, handleWsofflineCompile, handleRpcCall, HandleWebSocket
```

#### Debug (Function)
```rust
// Lines 133-135 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
func Debug(subsystem, msg string, telemetry map[string]interface{})
//  â³ Calls: submitLog
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\parser\markdown_parser.go (275 lines)

#### ParseMarkdown (Function)
```rust
// Lines 27-270 (244 LOC | Complexity 72) | used by 1 callers | [MutatesState, Tested, HighComplexity]
func ParseMarkdown(mdContent string) (*models.ResumeMatrix, error)
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, ResumeMatrix, parseYAML
//  â³ Called by: TestParseMarkdown
```

#### parseYAML (Function)
```rust
// Lines 272-302 (31 LOC | Complexity 11) | used by 1 callers | [MutatesState]
func parseYAML(line string, basics *models.Basics)
//  â³ Calls: Basics
//  â³ Called by: ParseMarkdown
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\resume_handler.go (455 lines)

#### parseRequestBody (Function)
```rust
// Lines 29-81 (53 LOC | Complexity 9) | used by 3 callers | [MutatesState]
func parseRequestBody(c *fiber.Ctx) (map[string]string, error)
//  â³ Called by: ListCompiledHandler, CompilePdfHandler, UpdateMatrixHandler
```

#### uploadToCAS (Function)
```rust
// Lines 281-347 (67 LOC | Complexity 12) | used by 2 callers | [Io]
func uploadToCAS(pdfBytes []byte) (string, error)
//  â³ Called by: CompilePdfHandler, handleWsofflineCompile
```

#### GetTemplatesHandler (Function)
```rust
// Lines 397-424 (28 LOC | Complexity 5) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func GetTemplatesHandler(c *fiber.Ctx) error
//  â³ Calls: sendResponse, Error
```

#### ListCompiledHandler (Function)
```rust
// Lines 427-498 (72 LOC | Complexity 15) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func ListCompiledHandler(c *fiber.Ctx) error
//  â³ Calls: Error, sendResponse, parseRequestBody
```

#### HealthCheckHandler (Function)
```rust
// Lines 501-503 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
func HealthCheckHandler(c *fiber.Ctx) error
```

#### sendResponse (Function)
```rust
// Lines 84-112 (29 LOC | Complexity 5) | used by 5 callers | [MutatesState, Io]
func sendResponse(c *fiber.Ctx, status int, data interface{}) error
//  â³ Calls: Error
//  â³ Called by: ListCompiledHandler, GetTemplatesHandler, CompilePdfHandler, UpdateMatrixHandler, GetMatrixHandler
```

#### GetMatrixHandler (Function)
```rust
// Lines 115-128 (14 LOC | Complexity 3) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func GetMatrixHandler(c *fiber.Ctx) error
//  â³ Calls: sendResponse, Error
```

#### saveCompilationToHistory (Function)
```rust
// Lines 351-394 (44 LOC | Complexity 7) | used by 2 callers | [MutatesState, Io]
func saveCompilationToHistory(templateID string, exhibitID string, jd string) error
//  â³ Calls: Info, Error
//  â³ Called by: CompilePdfHandler, handleWsofflineCompile
```

#### UpdateMatrixHandler (Function)
```rust
// Lines 131-161 (31 LOC | Complexity 6) | used by 0 callers | [MutatesState, Io, PotentialDeadCode]
func UpdateMatrixHandler(c *fiber.Ctx) error
//  â³ Calls: ResumeMatrix, Info, Error, sendResponse, parseRequestBody
```

#### CompilePdfHandler (Function)
```rust
// Lines 164-277 (114 LOC | Complexity 28) | used by 0 callers | [Async, MutatesState, Io, HighComplexity, PotentialDeadCode]
func CompilePdfHandler(c *fiber.Ctx) error
//  â³ Calls: ResumeMatrix, saveCompilationToHistory, uploadToCAS, CompileTypst, TailorResume, FilterResume, DefaultTailorConfig, parseRequestBody, sendResponse, Error
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\sdui_blueprint_loader.go (130 lines)

#### hydrateString (Function)
```rust
// Lines 126-143 (18 LOC | Complexity 6) | used by 1 callers | [MutatesState]
func hydrateString(str string, ctx map[string]interface{}) interface{}
//  â³ Called by: hydrateValue
```

#### LoadAndHydrateBlueprint (Function)
```rust
// Lines 12-48 (37 LOC | Complexity 14) | used by 2 callers | [MutatesState, Io, Tested]
func LoadAndHydrateBlueprint(screenId string, ctx map[string]interface{}) (interface{}, error)
//  â³ Calls: hydrateValue
//  â³ Called by: main, assembleScreen
```

#### hydrateValue (Function)
```rust
// Lines 50-124 (75 LOC | Complexity 19) | used by 1 callers | [MutatesState]
func hydrateValue(node interface{}, ctx map[string]interface{}) interface{}
//  â³ Calls: hydrateString
//  â³ Called by: LoadAndHydrateBlueprint
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\compiler\typst_compiler_test.go (37 lines)

#### TestCompileTypst (Function)
```rust
// Lines 9-45 (37 LOC | Complexity 4) | used by 0 callers | [Io, Tested, PotentialDeadCode]
func TestCompileTypst(t *testing.T)
//  â³ Calls: WorkItem, Basics, ResumeMatrix, CompileTypst
```

### C:\horAIzon_2.0\shua_modules\shua_resume\cmd\main.go (42 lines)

#### main (Function)
```rust
// Lines 12-53 (42 LOC | Complexity 4) | used by 0 callers | [Io, CanPanic, EntryPoint]
func main()
//  â³ Calls: Error, InitDB, Info
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\compiler\typst_compiler.go (104 lines)

#### resolveTypstPath (Function)
```rust
// Lines 38-66 (29 LOC | Complexity 6) | used by 1 callers | [Pure]
func resolveTypstPath() string
//  â³ Called by: CompileTypst
```

#### findModuleRoot (Function)
```rust
// Lines 18-35 (18 LOC | Complexity 5) | used by 1 callers | [MutatesState]
func findModuleRoot() string
//  â³ Called by: CompileTypst
```

#### CompileTypst (Function)
```rust
// Lines 70-126 (57 LOC | Complexity 4) | used by 3 callers | [MutatesState, Io, Tested]
func CompileTypst(matrix *models.ResumeMatrix, templateName string) ([]byte, error)
//  â³ Calls: ResumeMatrix, Info, Error, findModuleRoot, resolveTypstPath
//  â³ Called by: CompilePdfHandler, handleWsofflineCompile, TestCompileTypst
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\models\resume.go (81 lines)

#### ProjectItem (Struct)
```rust
// Lines 60-68 (9 LOC | Complexity 1) | used by 5 callers
ProjectItem struct
//  â³ Called by: TestFilterResume, main, ParseMarkdown, handleMatrixCrud, ResumeMatrix
```

#### Certificate (Struct)
```rust
// Lines 77-83 (7 LOC | Complexity 1) | used by 3 callers
Certificate struct
//  â³ Called by: ParseMarkdown, handleMatrixCrud, ResumeMatrix
```

#### Location (Struct)
```rust
// Lines 23-27 (5 LOC | Complexity 1) | used by 1 callers
Location struct
//  â³ Called by: Basics
```

#### Award (Struct)
```rust
// Lines 85-91 (7 LOC | Complexity 1) | used by 3 callers
Award struct
//  â³ Called by: ParseMarkdown, handleMatrixCrud, ResumeMatrix
```

#### Profile (Struct)
```rust
// Lines 29-33 (5 LOC | Complexity 1) | used by 1 callers
Profile struct
//  â³ Called by: Basics
```

#### WorkItem (Struct)
```rust
// Lines 35-46 (12 LOC | Complexity 1) | used by 6 callers
WorkItem struct
//  â³ Called by: TestFilterResume, main, ParseMarkdown, handleMatrixCrud, ResumeMatrix, TestCompileTypst
```

#### ResumeMatrix (Struct)
```rust
// Lines 2-10 (9 LOC | Complexity 1) | used by 11 callers | [CorePrimitive]
ResumeMatrix struct
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, Basics
//  â³ Called by: TestFilterResume, TailorResume, FilterResume, CompileTypst, CompilePdfHandler, UpdateMatrixHandler, ParseMarkdown, handleMatrixCrud, handleWsofflineCompile, assembleScreen, TestCompileTypst
```

#### Basics (Struct)
```rust
// Lines 12-21 (10 LOC | Complexity 1) | used by 3 callers
Basics struct
//  â³ Calls: Profile, Location
//  â³ Called by: parseYAML, ResumeMatrix, TestCompileTypst
```

#### Skill (Struct)
```rust
// Lines 70-75 (6 LOC | Complexity 1) | used by 3 callers
Skill struct
//  â³ Called by: ParseMarkdown, handleMatrixCrud, ResumeMatrix
```

#### Education (Struct)
```rust
// Lines 48-58 (11 LOC | Complexity 1) | used by 4 callers
Education struct
//  â³ Called by: main, ParseMarkdown, handleMatrixCrud, ResumeMatrix
```

### C:\horAIzon_2.0\shua_modules\shua_resume\test_matrix.go (17 lines)

#### main (Function)
```rust
// Lines 9-25 (17 LOC | Complexity 2) | used by 0 callers | [MutatesState, Io, EntryPoint]
func main()
//  â³ Calls: ProjectItem, Education, WorkItem, LoadAndHydrateBlueprint
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\handlers\websocket_handler.go (1071 lines)

#### parseListEditorString (Function)
```rust
// Lines 861-883 (23 LOC | Complexity 8) | used by 1 callers | [MutatesState]
func parseListEditorString(val interface{}) []string
//  â³ Called by: handleMatrixCrud
```

#### getCompiledHistory (Function)
```rust
// Lines 590-642 (53 LOC | Complexity 13) | used by 1 callers | [MutatesState, Io]
func getCompiledHistory(params map[string]interface{}) ([]map[string]interface{}, error)
//  â³ Called by: handleRpcCall
```

#### ReqRpc (Struct)
```rust
// Lines 162-166 (5 LOC | Complexity 1) | used by 4 callers
ReqRpc struct
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall, HandleWebSocket
```

#### SocketConnection.Emit (Function)
```rust
// Lines 31-51 (21 LOC | Complexity 4) | used by 4 callers | [MutatesState, Io]
func (s *SocketConnection) Emit(event string, payload interface{}) error
//  â³ Calls: SocketConnection
//  â³ Called by: handleWsofflineCompile, sendRpcSuccess, sendRpcError, handleRpcCall
```

#### handleMatrixCrud (Function)
```rust
// Lines 893-1116 (224 LOC | Complexity 47) | used by 1 callers | [MutatesState, Io, HighComplexity]
func handleMatrixCrud(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: Award, Certificate, Skill, ProjectItem, Education, WorkItem, ResumeMatrix, ReqRpc, SocketConnection, sendRpcSuccess, parseBoolStr, parseListEditorString, sendRpcError
//  â³ Called by: handleRpcCall
```

#### sendRpcSuccess (Function)
```rust
// Lines 266-276 (11 LOC | Complexity 2) | used by 3 callers | [MutatesState]
func sendRpcSuccess(s *SocketConnection, txId string, data interface{})
//  â³ Calls: SocketConnection, SocketConnection.Emit
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall
```

#### assembleScreen (Function)
```rust
// Lines 278-564 (287 LOC | Complexity 59) | used by 1 callers | [MutatesState, Io, HighComplexity]
func assembleScreen(screenId string) (interface{}, error)
//  â³ Calls: ResumeMatrix, LoadAndHydrateBlueprint, Error
//  â³ Called by: handleRpcCall
```

#### SocketConnection (Struct)
```rust
// Lines 26-29 (4 LOC | Complexity 1) | used by 7 callers
SocketConnection struct
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, sendRpcSuccess, sendRpcError, handleRpcCall, HandleWebSocket, SocketConnection.Emit
```

#### parseBoolStr (Function)
```rust
// Lines 885-891 (7 LOC | Complexity 3) | used by 1 callers | [Pure]
func parseBoolStr(val interface{}) bool
//  â³ Called by: handleMatrixCrud
```

#### sendRpcError (Function)
```rust
// Lines 256-264 (9 LOC | Complexity 1) | used by 3 callers | [MutatesState]
func sendRpcError(s *SocketConnection, txId string, message string)
//  â³ Calls: SocketConnection, SocketConnection.Emit
//  â³ Called by: handleMatrixCrud, handleWsofflineCompile, handleRpcCall
```

#### handleWsofflineCompile (Function)
```rust
// Lines 644-855 (212 LOC | Complexity 22) | used by 1 callers | [Async, MutatesState, Io, HighComplexity]
func handleWsofflineCompile(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: ResumeMatrix, ReqRpc, SocketConnection, sendRpcSuccess, saveCompilationToHistory, uploadToCAS, CompileTypst, TailorResume, FilterResume, DefaultTailorConfig, Error, SocketConnection.Emit, Info, sendRpcError
//  â³ Called by: handleRpcCall
```

#### handleRpcCall (Function)
```rust
// Lines 168-254 (87 LOC | Complexity 15) | used by 1 callers | [Async, MutatesState, Io]
func handleRpcCall(s *SocketConnection, rpc ReqRpc)
//  â³ Calls: ReqRpc, SocketConnection, getCompiledHistory, getTemplatesList, handleMatrixCrud, handleWsofflineCompile, sendRpcSuccess, SocketConnection.Emit, Error, assembleScreen, sendRpcError, Info
//  â³ Called by: HandleWebSocket
```

#### getTemplatesList (Function)
```rust
// Lines 566-588 (23 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io]
func getTemplatesList() ([]map[string]interface{}, error)
//  â³ Called by: handleRpcCall
```

#### RpcRequest (Struct)
```rust
// Lines 53-57 (5 LOC | Complexity 1) | used by 0 callers
RpcRequest struct
```

#### HandleWebSocket (Function)
```rust
// Lines 60-159 (100 LOC | Complexity 23) | used by 0 callers | [Async, MutatesState, Io, HighComplexity, PotentialDeadCode]
func HandleWebSocket(c *websocket.Conn)
//  â³ Calls: ReqRpc, SocketConnection, handleRpcCall, Info, Error
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\parser\markdown_parser_test.go (143 lines)

#### TestParseMarkdown (Function)
```rust
// Lines 6-148 (143 LOC | Complexity 44) | used by 0 callers | [Io, Tested, HighComplexity, PotentialDeadCode]
func TestParseMarkdown(t *testing.T)
//  â³ Calls: ParseMarkdown
```

### C:\horAIzon_2.0\shua_modules\shua_resume\pkg\ai\tailor_test.go (59 lines)

#### TestTokenize (Function)
```rust
// Lines 8-18 (11 LOC | Complexity 3) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
func TestTokenize(t *testing.T)
//  â³ Calls: Tokenize
```

#### TestJaccardSimilarity (Function)
```rust
// Lines 20-31 (12 LOC | Complexity 2) | used by 0 callers | [MutatesState, Tested, PotentialDeadCode]
func TestJaccardSimilarity(t *testing.T)
//  â³ Calls: JaccardSimilarity
```

#### TestFilterResume (Function)
```rust
// Lines 33-68 (36 LOC | Complexity 5) | used by 0 callers | [Pure, Tested, PotentialDeadCode]
func TestFilterResume(t *testing.T)
//  â³ Calls: ProjectItem, WorkItem, ResumeMatrix, DefaultTailorConfig, FilterResume
```


