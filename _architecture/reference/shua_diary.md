# Repository Export

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\rate_limiter.ts (103 lines)

#### AiRateLimiter.refill (Function)
```rust
// Lines 32-43 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private refill(): void
//  â³ Called by: AiRateLimiter.execute
```

#### AiRateLimiter.constructor (Function)
```rust
// Lines 23-27 (5 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor(private rpmCeiling: number = 15, private burstMax: number = 5)
```

#### AiRateLimiter (Class)
```rust
// Lines 11-72 (62 LOC | Complexity 1) | used by 4 callers
class AiRateLimiter
//  â³ Called by: GeminiJbcProvider.constructor, GeminiAnalyzerProvider.constructor, GeminiGeneratorProvider.constructor, DiaryAiSession
```

#### AiRateLimiter.execute (Function)
```rust
// Lines 48-71 (24 LOC | Complexity 3) | used by 18 callers | [Async, MutatesState, Io, CorePrimitive]
async execute<T>(task: () => Promise<T>): Promise<T>
//  â³ Calls: warn, AiRateLimiter.refill
//  â³ Called by: GeminiJbcProvider.generateSummary, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, GeminiAnalyzerProvider.analyze, cmd_raw_sql, cmd_schema, cmd_set_mood, cmd_add_entry, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, cmd_pick_entry, cmd_list_blocks, cmd_list_entries, get_conn, GeminiGeneratorProvider.generateFromNotesStream, GeminiGeneratorProvider.generateFromNotes
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\request_screen.ts (14 lines)

#### RequestScreenHandler (Class)
```rust
// Lines 3-10 (8 LOC | Complexity 1) | used by 1 callers
class RequestScreenHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### RequestScreenHandler.handle (Function)
```rust
// Lines 4-9 (6 LOC | Complexity 1) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, SduiOrchestrator.sendReplacePayload
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_jbc_provider.ts (680 lines)

#### OllamaJbcProvider (Class)
```rust
// Lines 5-353 (349 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class OllamaJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

#### OllamaJbcProvider.generateSummary (Function)
```rust
// Lines 264-311 (48 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
```

#### OllamaJbcProvider.constructor (Function)
```rust
// Lines 6-9 (4 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
```

#### OllamaJbcProvider.compileJbc (Function)
```rust
// Lines 14-112 (99 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, JbcTranslator.translate, JbcTranslator.parse, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, JbcTranslator.serializeDiaryState, OllamaJbcProvider.resolvePositionalRefs
```

#### OllamaJbcProvider.resolvePositionalRefs (Function)
```rust
// Lines 316-352 (37 LOC | Complexity 5) | used by 1 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, blocks: any[]): string
//  â³ Called by: OllamaJbcProvider.compileJbc
```

#### OllamaJbcProvider.presentJbcStream (Function)
```rust
// Lines 117-259 (143 LOC | Complexity 20) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, JbcTranslator.parse, JbcTranslator.serializeDiaryState
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_node_builder.ts (174 lines)

#### SduiNodeBuilder (Class)
```rust
// Lines 4-98 (95 LOC | Complexity 1) | used by 0 callers
class SduiNodeBuilder
```

#### SduiNodeBuilder.hydrateString (Function)
```rust
// Lines 86-97 (12 LOC | Complexity 2) | used by 1 callers | [Pure]
private static hydrateString(str: string, context: HydrationContext): any
//  â³ Called by: SduiNodeBuilder.hydrateNode
```

#### SduiNodeBuilder.hydrateNode (Function)
```rust
// Lines 25-80 (56 LOC | Complexity 16) | used by 3 callers | [MutatesState]
static hydrateNode(node: any, context: HydrationContext): any
//  â³ Calls: SduiNodeBuilder.hydrateString
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, SduiNodeBuilder.buildScreen
```

#### SduiNodeBuilder.buildScreen (Function)
```rust
// Lines 10-20 (11 LOC | Complexity 2) | used by 2 callers | [MutatesState, Io, CanPanic]
static buildScreen(moduleName: string, screenKey: string, context: HydrationContext): any
//  â³ Calls: SduiNodeBuilder.hydrateNode, SduiBlueprintLoader.loadBlueprint
//  â³ Called by: SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryList
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_generator_provider.ts (266 lines)

#### GeminiGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 79-137 (59 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
//  â³ Calls: JbcTranslator.parse, AiRateLimiter.execute
```

#### GeminiGeneratorProvider (Class)
```rust
// Lines 4-138 (135 LOC | Complexity 1) | used by 1 callers
class GeminiGeneratorProvider implements IDiaryGeneratorProvider
//  â³ Calls: IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create
```

#### GeminiGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 11-77 (67 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint>
//  â³ Calls: DiaryBlueprint, JbcTranslator.parse, AiRateLimiter.execute
```

#### GeminiGeneratorProvider.constructor (Function)
```rust
// Lines 5-9 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_generator_provider.ts (280 lines)

#### OllamaGeneratorProvider.constructor (Function)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
```

#### OllamaGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 9-78 (70 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async generateFromNotes(rawNotes: string, style: string): Promise<DiaryBlueprint>
//  â³ Calls: DiaryBlueprint, JbcTranslator.parse
```

#### OllamaGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 80-143 (64 LOC | Complexity 10) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
//  â³ Calls: JbcTranslator.parse
```

#### OllamaGeneratorProvider (Class)
```rust
// Lines 3-144 (142 LOC | Complexity 1) | used by 1 callers
class OllamaGeneratorProvider implements IDiaryGeneratorProvider
//  â³ Calls: IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_diary_generator.ts (18 lines)

#### IDiaryGeneratorProvider.generateFromNotesStream (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
generateFromNotesStream(rawNotes: string, style: string): AsyncIterable<string>
```

#### IDiaryGeneratorProvider (Interface)
```rust
// Lines 8-14 (7 LOC | Complexity 1) | used by 4 callers
interface IDiaryGeneratorProvider
//  â³ Called by: DiaryAiSession.create, DiaryAiSession.constructor, GeminiGeneratorProvider, OllamaGeneratorProvider
```

#### DiaryBlueprint (Interface)
```rust
// Lines 1-6 (6 LOC | Complexity 1) | used by 3 callers
interface DiaryBlueprint
//  â³ Called by: IDiaryGeneratorProvider.generateFromNotes, GeminiGeneratorProvider.generateFromNotes, OllamaGeneratorProvider.generateFromNotes
```

#### IDiaryGeneratorProvider.generateFromNotes (Function)
```rust
// Lines 9-12 (4 LOC | Complexity 1) | used by 0 callers | [Async, Pure, FrameworkInvoked]
generateFromNotes(
//  â³ Calls: DiaryBlueprint
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_block_registry.ts (608 lines)

#### SduiBlockRegistry.getAiEditableTypes (Function)
```rust
// Lines 200-205 (6 LOC | Complexity 3) | used by 2 callers | [Pure]
static getAiEditableTypes(): string[]
//  â³ Calls: SduiBlockRegistry._ensureLoaded
//  â³ Called by: GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc
```

#### SduiBlockRegistry (Class)
```rust
// Lines 35-345 (311 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiBlockRegistry
//  â³ Calls: BlockTypeSpec
```

#### SduiBlockRegistry.isSystemOwned (Function)
```rust
// Lines 221-226 (6 LOC | Complexity 5) | used by 2 callers | [Pure, Cycle]
static isSystemOwned(blockType: string): boolean
//  â³ Calls: SduiBlockRegistry.get, SduiBlockRegistry._ensureLoaded
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### SduiBlockRegistry.all (Function)
```rust
// Lines 190-198 (9 LOC | Complexity 1) | used by 8 callers | [Pure]
static all(): Array<{ blockType: string; spec: BlockTypeSpec }>
//  â³ Calls: BlockTypeSpec, SduiBlockRegistry._ensureLoaded
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, DiaryRepository.searchEntries, DiaryRepository.getAllEmbeddings, DiaryRepository.getEntryBlocks, DiaryRepository.getMoodTimeline, DiaryRepository.getEntriesList, checkAndSynthesizeForUser, runMonthlySynthesisCheck
```

#### SduiBlockRegistry.isAiEditable (Function)
```rust
// Lines 214-219 (6 LOC | Complexity 5) | used by 0 callers | [Pure, PotentialDeadCode]
static isAiEditable(blockType: string): boolean
//  â³ Calls: SduiBlockRegistry.get, SduiBlockRegistry._ensureLoaded
```

#### SduiBlockRegistry.load (Function)
```rust
// Lines 45-144 (100 LOC | Complexity 23) | used by 2 callers | [Io, Cycle, HighComplexity]
static load(): void
//  â³ Calls: BlockTypeSpec, SduiStateVault.set, JbcTranslator.parse
//  â³ Called by: SduiBlockRegistry._ensureLoaded, SduiOrchestrator.constructor
```

#### SduiBlockRegistry._ensureLoaded (Function)
```rust
// Lines 339-344 (6 LOC | Complexity 2) | used by 6 callers | [Pure, Cycle]
private static _ensureLoaded(): void
//  â³ Calls: SduiBlockRegistry.load, SduiBlockRegistry._ensureWatcher
//  â³ Called by: SduiBlockRegistry.isSystemOwned, SduiBlockRegistry.isAiEditable, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, SduiBlockRegistry.all, SduiBlockRegistry.get
```

#### BlockTypeSpec (Interface)
```rust
// Lines 9-25 (17 LOC | Complexity 1) | used by 4 callers
interface BlockTypeSpec
//  â³ Called by: SduiBlockRegistry.all, SduiBlockRegistry.get, SduiBlockRegistry.load, SduiBlockRegistry
```

#### SduiBlockRegistry._ensureWatcher (Function)
```rust
// Lines 315-337 (23 LOC | Complexity 3) | used by 1 callers | [Io]
private static _ensureWatcher(): void
//  â³ Calls: warn
//  â³ Called by: SduiBlockRegistry._ensureLoaded
```

#### SduiBlockRegistry.getSystemOwnedTypes (Function)
```rust
// Lines 207-212 (6 LOC | Complexity 3) | used by 2 callers | [Pure]
static getSystemOwnedTypes(): string[]
//  â³ Calls: SduiBlockRegistry._ensureLoaded
//  â³ Called by: GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc
```

#### SduiBlockRegistry.get (Function)
```rust
// Lines 149-185 (37 LOC | Complexity 4) | used by 5 callers | [Io, Cycle]
static get(blockType: string): BlockTypeSpec
//  â³ Calls: BlockTypeSpec, warn, SduiBlockRegistry._ensureLoaded
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryList, SduiBlockRegistry.buildContentNode, SduiBlockRegistry.isSystemOwned, SduiBlockRegistry.isAiEditable
```

#### SduiBlockRegistry.buildContentNode (Function)
```rust
// Lines 231-311 (81 LOC | Complexity 25) | used by 1 callers | [Pure, HighComplexity]
static buildContentNode(
//  â³ Calls: JbcTranslator.parse, SduiBlockRegistry.get
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_orchestrator.ts (320 lines)

#### SduiOrchestrator.updateSession (Function)
```rust
// Lines 50-52 (3 LOC | Complexity 1) | used by 1 callers | [Io]
public updateSession(socketId: string, session: DiaryAiSession)
//  â³ Calls: DiaryAiSession, SduiStateVault.set
//  â³ Called by: SaveAiConfigHandler.handle
```

#### SduiOrchestrator.setupListeners (Function)
```rust
// Lines 82-108 (27 LOC | Complexity 3) | used by 1 callers | [MutatesState, Io]
private setupListeners()
//  â³ Calls: SduiOrchestrator.handleRpc, AnalysisWorker.cancelPendingForSocket, SduiStateVault.get, DiaryAiSession.create, getDiaryRepository, DiaryRepository.getAiProviderConfig, SduiStateVault, SduiStateVault.set
//  â³ Called by: SduiOrchestrator.constructor
```

#### SduiOrchestrator.handleRpc (Function)
```rust
// Lines 110-151 (42 LOC | Complexity 8) | used by 1 callers | [Async, MutatesState, Io]
private async handleRpc(socket: Socket, data: any)
//  â³ Calls: warn, SduiActionHandler.handle, SduiStateVault.set, DiaryAiSession.create, getDiaryRepository, DiaryRepository.getAiProviderConfig, SduiStateVault.get
//  â³ Called by: SduiOrchestrator.setupListeners
```

#### SduiOrchestrator.constructor (Function)
```rust
// Lines 30-37 (8 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor(io: Server)
//  â³ Calls: SduiOrchestrator.setupHotReloadWatcher, SduiOrchestrator.setupListeners, SduiOrchestrator.registerHandlers, SduiBlockRegistry.load
```

#### SduiOrchestrator (Class)
```rust
// Lines 21-188 (168 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiOrchestrator
//  â³ Calls: ISduiRpcHandler, DiaryAiSession, SduiStateVault
```

#### SduiOrchestrator.sendReplacePayload (Function)
```rust
// Lines 153-187 (35 LOC | Complexity 5) | used by 3 callers | [Async, Io]
public async sendReplacePayload(socket: Socket, screenId: string, params: Record<string, any>)
//  â³ Calls: DiaryRepository.getEntryWithBlocks, getDiaryRepository, SduiScreenAssembler.assemble
//  â³ Called by: GenerateFromNotesHandler.handle, ApplyMutationsHandler.handle, RequestScreenHandler.handle
```

#### SduiOrchestrator.setupHotReloadWatcher (Function)
```rust
// Lines 54-80 (27 LOC | Complexity 7) | used by 1 callers | [MutatesState, Io]
private setupHotReloadWatcher()
//  â³ Called by: SduiOrchestrator.constructor
```

#### SduiOrchestrator.registerHandlers (Function)
```rust
// Lines 39-48 (10 LOC | Complexity 1) | used by 1 callers | [Pure]
private registerHandlers()
//  â³ Calls: SaveAiConfigHandler, GenerateSummaryHandler, AnalyzeEntryHandler, SemanticSearchHandler, ApplyMutationsHandler, ChatHandler, GenerateFromNotesHandler, RequestScreenHandler, SduiStateVault.set
//  â³ Called by: SduiOrchestrator.constructor
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\python_semantics_analyzer_provider.ts (98 lines)

#### PythonSemanticsAnalyzerProvider.analyze (Function)
```rust
// Lines 9-53 (45 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, FrameworkInvoked, TraitMethod]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, JbcTranslator.parse
```

#### PythonSemanticsAnalyzerProvider (Class)
```rust
// Lines 3-54 (52 LOC | Complexity 1) | used by 1 callers
class PythonSemanticsAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: DiaryAiSession.create
```

#### PythonSemanticsAnalyzerProvider.constructor (Function)
```rust
// Lines 7-7 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(private pythonScriptPath: string) {}
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\generate_summary.ts (40 lines)

#### GenerateSummaryHandler.handle (Function)
```rust
// Lines 5-23 (19 LOC | Complexity 3) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext
```

#### GenerateSummaryHandler (Class)
```rust
// Lines 4-24 (21 LOC | Complexity 1) | used by 1 callers
class GenerateSummaryHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\lib\governor_logger.ts (114 lines)

#### log (Function)
```rust
// Lines 117-171 (55 LOC | Complexity 10) | used by 2 callers | [Io, CanPanic]
function log(
//  â³ Calls: header
//  â³ Called by: connectSocket, uuid
```

#### connectSocket (Function)
```rust
// Lines 46-86 (41 LOC | Complexity 5) | used by 0 callers | [Io, PotentialDeadCode]
function connectSocket(): void
//  â³ Calls: log
```

#### onConnect (Function)
```rust
// Lines 56-67 (12 LOC | Complexity 3) | used by 0 callers | [Io, PotentialDeadCode]
const onConnect = () =>
```

#### onError (Function)
```rust
// Lines 69-74 (6 LOC | Complexity 1) | used by 0 callers | [Io, FrameworkInvoked]
const onError = (err: any) =>
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\generate_from_notes.ts (116 lines)

#### GenerateFromNotesHandler (Class)
```rust
// Lines 5-63 (59 LOC | Complexity 1) | used by 1 callers
class GenerateFromNotesHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### GenerateFromNotesHandler.handle (Function)
```rust
// Lines 6-62 (57 LOC | Complexity 7) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, SduiOrchestrator.sendReplacePayload, DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, getDiaryRepository
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_search_service.ts (309 lines)

#### DiarySearchService (Class)
```rust
// Lines 52-240 (189 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiarySearchService
//  â³ Calls: RadixTrie
//  â³ Called by: DiarySearchService.getInstance
```

#### tokenize (Function)
```rust
// Lines 41-50 (10 LOC | Complexity 3) | used by 1 callers | [Pure]
function tokenize(text: string): Set<string>
//  â³ Called by: DiarySearchService.indexEntry
```

#### DiarySearchService.indexEntry (Function)
```rust
// Lines 101-131 (31 LOC | Complexity 8) | used by 1 callers | [MutatesState]
public indexEntry(entry: DiaryEntry, blocks: DiaryBlock[]): void
//  â³ Calls: DiaryBlock, DiaryEntry, JbcTranslator.parse, SduiStateVault.set, RadixTrie.insert, tokenize, DiarySearchService.removeEntry
//  â³ Called by: DiarySearchService.reconcile
```

#### DiarySearchService.reconcile (Function)
```rust
// Lines 167-217 (51 LOC | Complexity 10) | used by 1 callers | [MutatesState, Io]
public reconcile(
//  â³ Calls: DiaryEntry, DiaryBlock, DiarySearchService.indexEntry, JbcTranslator.parse, DiarySearchService.removeEntry
//  â³ Called by: SduiScreenAssembler._assembleDiaryList
```

#### DiarySearchService.constructor (Function)
```rust
// Lines 77-79 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
private constructor()
//  â³ Calls: RadixTrie
```

#### DiarySearchService.indexedEntryCount (Function)
```rust
// Lines 237-239 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
public get indexedEntryCount(): number
```

#### DiarySearchService.removeEntry (Function)
```rust
// Lines 139-150 (12 LOC | Complexity 3) | used by 2 callers | [MutatesState]
public removeEntry(entryId: string): void
//  â³ Calls: RadixTrie.remove
//  â³ Called by: DiarySearchService.reconcile, DiarySearchService.indexEntry
```

#### DiarySearchService.getInstance (Function)
```rust
// Lines 81-86 (6 LOC | Complexity 2) | used by 2 callers | [Pure]
public static getInstance(): DiarySearchService
//  â³ Calls: DiarySearchService
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, SduiActionHandler._searchDiary
```

#### DiarySearchService.search (Function)
```rust
// Lines 228-231 (4 LOC | Complexity 3) | used by 2 callers | [Pure]
public search(query: string, maxDistance: number): { [entryId: string]: SearchMatchDetail[] }
//  â³ Calls: SearchMatchDetail, RadixTrie.searchWithMatches
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, SduiActionHandler._searchDiary
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_blueprint_loader.ts (249 lines)

#### SduiBlueprintLoader.loadBlock (Function)
```rust
// Lines 145-175 (31 LOC | Complexity 4) | used by 0 callers | [Io, PotentialDeadCode]
static loadBlock(blockType: string): any | null
//  â³ Calls: SduiStateVault.set, JbcTranslator.parse, ensureWatcher
```

#### SduiBlueprintLoader.invalidate (Function)
```rust
// Lines 181-186 (6 LOC | Complexity 2) | used by 0 callers | [Io, PotentialDeadCode]
static invalidate(modulePath: string): void
```

#### watchDirectoryRecursive (Function)
```rust
// Lines 16-50 (35 LOC | Complexity 8) | used by 1 callers | [Io, Cycle]
function watchDirectoryRecursive(dirPath: string, callback: (changedAbsPath: string) => void): void
//  â³ Calls: ensureWatcher, SduiStateVault.set
//  â³ Called by: ensureWatcher
```

#### SduiBlueprintLoader.loadBlueprint (Function)
```rust
// Lines 103-132 (30 LOC | Complexity 4) | used by 3 callers | [Io, CanPanic]
static loadBlueprint(modulePath: string): any
//  â³ Calls: SduiStateVault.set, JbcTranslator.parse, ensureWatcher
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, SduiNodeBuilder.buildScreen
```

#### ensureWatcher (Function)
```rust
// Lines 52-83 (32 LOC | Complexity 7) | used by 3 callers | [Io, Cycle]
function ensureWatcher(dir: string): void
//  â³ Calls: watchDirectoryRecursive
//  â³ Called by: watchDirectoryRecursive, SduiBlueprintLoader.loadBlock, SduiBlueprintLoader.loadBlueprint
```

#### SduiBlueprintLoader (Class)
```rust
// Lines 85-195 (111 LOC | Complexity 1) | used by 0 callers
class SduiBlueprintLoader
```

#### SduiBlueprintLoader.invalidateAll (Function)
```rust
// Lines 191-194 (4 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
static invalidateAll(): void
//  â³ Calls: SduiStateVault.clear
```

### C:\horAIzon_2.0\shua_modules\shua_diary\db_debug.py (267 lines)

#### cmd_edit_title (Function)
```rust
// Lines 132-147 (16 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_edit_title(conn)
//  â³ Calls: ok, now_iso, AiRateLimiter.execute, warn, cmd_pick_entry, header
//  â³ Called by: c
```

#### cmd_list_blocks (Function)
```rust
// Lines 83-106 (24 LOC | Complexity 4) | used by 1 callers | [Io, Cycle]
def cmd_list_blocks(conn, entry_id=None)
//  â³ Calls: c, warn, AiRateLimiter.execute, header
//  â³ Called by: c
```

#### cmd_add_entry (Function)
```rust
// Lines 215-236 (22 LOC | Complexity 1) | used by 1 callers | [Io]
def cmd_add_entry(conn)
//  â³ Calls: ok, now_iso, AiRateLimiter.execute, header
//  â³ Called by: c
```

#### cmd_set_mood (Function)
```rust
// Lines 239-257 (19 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_set_mood(conn)
//  â³ Calls: ok, now_iso, AiRateLimiter.execute, err, cmd_pick_entry, header
//  â³ Called by: c
```

#### cmd_reset_all (Function)
```rust
// Lines 201-212 (12 LOC | Complexity 2) | used by 1 callers | [Io]
def cmd_reset_all(conn)
//  â³ Calls: ok, AiRateLimiter.execute, warn, header
//  â³ Called by: c
```

#### repl (Function)
```rust
// Lines 317-353 (37 LOC | Complexity 8) | used by 1 callers | [Io, Cycle]
def repl()
//  â³ Calls: warn, DiaryRepository.close, ok, get_conn, c, err
//  â³ Called by: c
```

#### cmd_pick_entry (Function)
```rust
// Lines 109-129 (21 LOC | Complexity 6) | used by 5 callers | [Io, Cycle]
def cmd_pick_entry(conn) -> str | None
//  â³ Calls: err, c, warn, AiRateLimiter.execute
//  â³ Called by: c, cmd_set_mood, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title
```

#### cmd_delete_entry (Function)
```rust
// Lines 185-198 (14 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_delete_entry(conn)
//  â³ Calls: ok, AiRateLimiter.execute, c, cmd_pick_entry, warn, header
//  â³ Called by: c
```

#### cmd_raw_sql (Function)
```rust
// Lines 274-296 (23 LOC | Complexity 6) | used by 1 callers | [Io, Cycle]
def cmd_raw_sql(conn)
//  â³ Calls: err, AiRateLimiter.execute, warn, c, header
//  â³ Called by: c
```

#### cmd_edit_block_content (Function)
```rust
// Lines 150-182 (33 LOC | Complexity 5) | used by 1 callers | [Io, Cycle]
def cmd_edit_block_content(conn)
//  â³ Calls: ok, now_iso, c, warn, AiRateLimiter.execute, cmd_pick_entry, header
//  â³ Called by: c
```

#### warn (Function)
```rust
// Lines 40-40 (1 LOC | Complexity 1) | used by 23 callers | [Io, CorePrimitive]
def warn(msg):      print(f"{YELLOW}[!!]{RESET} {msg}")
//  â³ Called by: AnalysisWorker._processNext, getEmbedding, OllamaAnalyzerProvider.analyze, SduiBlockRegistry._ensureWatcher, SduiBlockRegistry.get, AiRateLimiter.execute, SduiOrchestrator.handleRpc, GeminiAnalyzerProvider.analyze, SduiActionHandler.handle, SduiDeltaEmitter._emit, JbcTranslator.parse, JbcTranslator.translate, uuid, repl, cmd_raw_sql, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, cmd_pick_entry, cmd_list_blocks, cmd_list_entries, checkAndSynthesizeForUser
```

#### err (Function)
```rust
// Lines 41-41 (1 LOC | Complexity 1) | used by 4 callers | [Io]
def err(msg):       print(f"{RED}[XX]{RESET} {msg}")
//  â³ Called by: repl, cmd_raw_sql, cmd_set_mood, cmd_pick_entry
```

#### cmd_schema (Function)
```rust
// Lines 260-271 (12 LOC | Complexity 3) | used by 1 callers | [Io, Cycle]
def cmd_schema(conn)
//  â³ Calls: AiRateLimiter.execute, c, header
//  â³ Called by: c
```

#### header (Function)
```rust
// Lines 38-38 (1 LOC | Complexity 1) | used by 11 callers | [Io, CorePrimitive]
def header(text):   print(f"\n{BOLD}{CYAN}{'='*60}{RESET}\n{BOLD}{CYAN}  {text}{RESET}\n{BOLD}{CYAN}{'='*60}{RESET}")
//  â³ Called by: log, cmd_raw_sql, cmd_schema, cmd_set_mood, cmd_add_entry, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title, cmd_list_blocks, cmd_list_entries
```

#### get_conn (Function)
```rust
// Lines 46-52 (7 LOC | Complexity 1) | used by 1 callers | [Io]
def get_conn() -> sqlite3.Connection
//  â³ Calls: AiRateLimiter.execute
//  â³ Called by: repl
```

#### c (Function)
```rust
// Lines 37-37 (1 LOC | Complexity 1) | used by 8 callers | [Pure, Cycle]
def c(text, color): return f"{color}{text}{RESET}"
//  â³ Calls: repl, cmd_raw_sql, cmd_schema, cmd_reset_all, cmd_delete_entry, cmd_add_entry, cmd_set_mood, cmd_edit_block_content, cmd_edit_title, cmd_pick_entry, cmd_list_blocks, cmd_list_entries
//  â³ Called by: repl, cmd_raw_sql, cmd_schema, cmd_delete_entry, cmd_edit_block_content, cmd_pick_entry, cmd_list_blocks, cmd_list_entries
```

#### cmd_list_entries (Function)
```rust
// Lines 61-80 (20 LOC | Complexity 5) | used by 1 callers | [Io, Cycle]
def cmd_list_entries(conn)
//  â³ Calls: c, warn, AiRateLimiter.execute, header
//  â³ Called by: c
```

#### now_iso (Function)
```rust
// Lines 55-56 (2 LOC | Complexity 1) | used by 4 callers | [Pure]
def now_iso() -> str
//  â³ Called by: cmd_set_mood, cmd_add_entry, cmd_edit_block_content, cmd_edit_title
```

#### ok (Function)
```rust
// Lines 39-39 (1 LOC | Complexity 1) | used by 7 callers | [Io]
def ok(msg):        print(f"{GREEN}[OK]{RESET} {msg}")
//  â³ Called by: repl, cmd_set_mood, cmd_add_entry, cmd_reset_all, cmd_delete_entry, cmd_edit_block_content, cmd_edit_title
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\diary_ai_session.ts (95 lines)

#### DiaryAiSession.constructor (Function)
```rust
// Lines 33-38 (6 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
constructor(
//  â³ Calls: AnalysisWorker, IAnalyzerProvider, IJbcChatProvider, IDiaryGeneratorProvider
```

#### AiProviderConfig (Interface)
```rust
// Lines 19-27 (9 LOC | Complexity 1) | used by 1 callers
interface AiProviderConfig
//  â³ Called by: DiaryAiSession.create
```

#### DiaryAiSession.create (Function)
```rust
// Lines 40-73 (34 LOC | Complexity 5) | used by 4 callers | [MutatesState, Io]
static create(config: AiProviderConfig, socket: Socket): DiaryAiSession
//  â³ Calls: IAnalyzerProvider, IJbcChatProvider, IDiaryGeneratorProvider, AiProviderConfig, DiaryAiSession, AnalysisWorker, N8nJbcProvider, OllamaAnalyzerProvider, PythonSemanticsAnalyzerProvider, OllamaJbcProvider, OllamaGeneratorProvider, GeminiAnalyzerProvider, GeminiJbcProvider, GeminiGeneratorProvider
//  â³ Called by: SaveAiConfigHandler.handle, SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, checkAndSynthesizeForUser
```

#### DiaryAiSession (Class)
```rust
// Lines 29-74 (46 LOC | Complexity 1) | used by 4 callers
class DiaryAiSession
//  â³ Calls: AiRateLimiter
//  â³ Called by: SduiOrchestrator.updateSession, SduiOrchestrator, SduiRpcContext, DiaryAiSession.create
```

### C:\horAIzon_2.0\shua_modules\shua_diary\start_diary.py (106 lines)

#### main (Function)
```rust
// Lines 10-112 (103 LOC | Complexity 17) | used by 1 callers | [Io, Cycle, EntryPoint]
def main()
//  â³ Calls: is_port_in_use
//  â³ Called by: is_port_in_use
```

#### is_port_in_use (Function)
```rust
// Lines 6-8 (3 LOC | Complexity 1) | used by 1 callers | [Io, Cycle]
def is_port_in_use(port)
//  â³ Calls: main
//  â³ Called by: main
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\chat.ts (136 lines)

#### ChatHandler (Class)
```rust
// Lines 5-73 (69 LOC | Complexity 1) | used by 1 callers
class ChatHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### ChatHandler.handle (Function)
```rust
// Lines 6-72 (67 LOC | Complexity 9) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, JbcTranslator.translate, JbcTranslator.parse
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\ollama_analyzer_provider.ts (197 lines)

#### OllamaAnalyzerProvider (Class)
```rust
// Lines 3-102 (100 LOC | Complexity 1) | used by 1 callers
class OllamaAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: DiaryAiSession.create
```

#### OllamaAnalyzerProvider.constructor (Function)
```rust
// Lines 4-8 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: IAnalyzerProvider
```

#### OllamaAnalyzerProvider.analyze (Function)
```rust
// Lines 10-101 (92 LOC | Complexity 9) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, IAnalyzerProvider.analyze, warn, JbcTranslator.parse
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\analysis_worker.ts (338 lines)

#### AnalysisWorker.constructor (Function)
```rust
// Lines 39-42 (4 LOC | Complexity 1) | used by 0 callers | [Io, FrameworkInvoked]
constructor(
//  â³ Calls: IAnalyzerProvider
```

#### AnalysisWorker._pushDelta (Function)
```rust
// Lines 176-206 (31 LOC | Complexity 2) | used by 1 callers | [Io]
private _pushDelta(entryId: string, result: AnalysisResult): void
//  â³ Calls: AnalysisResult, SduiDeltaEmitter.emitPatch
//  â³ Called by: AnalysisWorker._processNext
```

#### AnalysisWorker (Class)
```rust
// Lines 30-207 (178 LOC | Complexity 1) | used by 2 callers | [HighComplexity]
class AnalysisWorker
//  â³ Calls: PendingJob
//  â³ Called by: DiaryAiSession.constructor, DiaryAiSession.create
```

#### AnalysisWorker.cancelPendingForSocket (Function)
```rust
// Lines 77-81 (5 LOC | Complexity 1) | used by 1 callers | [MutatesState, Io]
cancelPendingForSocket(): void
//  â³ Called by: SduiOrchestrator.setupListeners
```

#### AnalysisWorker.queueDepth (Function)
```rust
// Lines 73-75 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
get queueDepth(): number
```

#### AnalysisWorker._processNext (Function)
```rust
// Lines 95-174 (80 LOC | Complexity 4) | used by 1 callers | [Async, MutatesState, Io]
private async _processNext(): Promise<void>
//  â³ Calls: AnalysisResult, IAnalyzerProvider.analyze, AnalysisWorker._pushDelta, getDiaryRepository, DiaryRepository.updateEntryAnalysis, warn, AnalysisWorker._setStatus
//  â³ Called by: AnalysisWorker.enqueue
```

#### PendingJob (Interface)
```rust
// Lines 7-10 (4 LOC | Complexity 1) | used by 1 callers
interface PendingJob
//  â³ Called by: AnalysisWorker
```

#### AnalysisWorker.enqueue (Function)
```rust
// Lines 49-67 (19 LOC | Complexity 4) | used by 1 callers | [MutatesState, Io]
enqueue(entryId: string, blocks: Array<{ blockType: string; content: string }>): void
//  â³ Calls: AnalysisWorker._processNext, AnalysisWorker._setStatus
//  â³ Called by: AnalyzeEntryHandler.handle
```

#### AnalysisWorker.getStatus (Function)
```rust
// Lines 69-71 (3 LOC | Complexity 2) | used by 0 callers | [Pure, PotentialDeadCode]
getStatus(entryId: string): AnalysisStatus | null
```

#### AnalysisWorker._setStatus (Function)
```rust
// Lines 83-93 (11 LOC | Complexity 3) | used by 2 callers | [MutatesState, Io]
private _setStatus(entryId: string, status: AnalysisStatus): void
//  â³ Calls: SduiStateVault.set
//  â³ Called by: AnalysisWorker._processNext, AnalysisWorker.enqueue
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\apply_mutations.ts (132 lines)

#### ApplyMutationsHandler.handle (Function)
```rust
// Lines 6-70 (65 LOC | Complexity 11) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, SduiOrchestrator.sendReplacePayload, DiaryRepository.createBlock, DiaryRepository._lexoRankAfter, DiaryRepository.getBlockLexoRank, DiaryRepository._midRankSuffix, DiaryRepository.stmt, DiaryRepository.updateBlock, DiaryRepository.deleteBlock, getDiaryRepository
```

#### ApplyMutationsHandler (Class)
```rust
// Lines 5-71 (67 LOC | Complexity 1) | used by 1 callers
class ApplyMutationsHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_analyzer_provider.ts (199 lines)

#### GeminiAnalyzerProvider.analyze (Function)
```rust
// Lines 11-103 (93 LOC | Complexity 8) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async analyze(content: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult, JbcTranslator.parse, AiRateLimiter.execute, warn
```

#### GeminiAnalyzerProvider (Class)
```rust
// Lines 4-104 (101 LOC | Complexity 1) | used by 1 callers
class GeminiAnalyzerProvider implements IAnalyzerProvider
//  â³ Calls: IAnalyzerProvider
//  â³ Called by: DiaryAiSession.create
```

#### GeminiAnalyzerProvider.constructor (Function)
```rust
// Lines 5-9 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\semantic_search.ts (110 lines)

#### SemanticSearchHandler.handle (Function)
```rust
// Lines 6-59 (54 LOC | Complexity 7) | used by 0 callers | [Async, Io, CanPanic, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, DiaryRepository.getBlockSearchDetails, cosineSimilarity, DiaryRepository.getAllEmbeddings, getDiaryRepository, getEmbedding
```

#### SemanticSearchHandler (Class)
```rust
// Lines 5-60 (56 LOC | Complexity 1) | used by 1 callers
class SemanticSearchHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_repository.ts (1464 lines)

#### DiaryRepository._nextLexoRank (Function)
```rust
// Lines 577-588 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private _nextLexoRank(userId: string): string
//  â³ Calls: DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.createEntry
```

#### DiaryRepository.reorderBlock (Function)
```rust
// Lines 335-340 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
reorderBlock(blockId: string, newLexoRank: string): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors
```

#### DiaryRepository._midRankSuffix (Function)
```rust
// Lines 558-574 (17 LOC | Complexity 5) | used by 3 callers | [Pure]
private static _midRankSuffix(lo: string, hi: string | undefined): string
//  â³ Called by: DiaryRepository._lexoRankAfter, DiaryRepository.reorderBlockByNeighbors, ApplyMutationsHandler.handle
```

#### DiaryRepository.getBlockSearchDetails (Function)
```rust
// Lines 667-682 (16 LOC | Complexity 1) | used by 2 callers | [MutatesState]
getBlockSearchDetails(blockId: string): { blockId: string; content: string; blockType: string; entryId: string; entryTitle: string } | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SemanticSearchHandler.handle, SduiActionHandler._searchDiary
```

#### DiaryRepository.getMoodTimeline (Function)
```rust
// Lines 211-232 (22 LOC | Complexity 1) | used by 1 callers | [MutatesState, Tested]
getMoodTimeline(userId: string, monthOffset: number = 0): Array<{ date: string; moodScore: number | null }>
//  â³ Calls: DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: SduiScreenAssembler._assembleDiaryList
```

#### DiaryRepository.deleteEntry (Function)
```rust
// Lines 483-487 (5 LOC | Complexity 1) | used by 1 callers | [MutatesState]
deleteEntry(entryId: string): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._deleteEntry
```

#### DiaryRepository.getAllEmbeddings (Function)
```rust
// Lines 746-758 (13 LOC | Complexity 1) | used by 1 callers | [MutatesState, Io]
getAllEmbeddings(): Array<{ blockId: string; embedding: number[] }>
//  â³ Calls: SduiBlockRegistry.all
//  â³ Called by: SemanticSearchHandler.handle
```

#### DiaryRepository.close (Function)
```rust
// Lines 838-840 (3 LOC | Complexity 1) | used by 2 callers | [Io]
close(): void
//  â³ Called by: uuid, repl
```

#### DiaryRepository.createBlock (Function)
```rust
// Lines 291-305 (15 LOC | Complexity 1) | used by 4 callers | [MutatesState]
createBlock(entryId: string, blockType: BlockType, afterLexoRank?: string): DiaryBlock
//  â³ Calls: DiaryBlock, DiaryRepository.getEntryBlocks, DiaryRepository.stmt, DiaryRepository._nextSortOrder, DiaryRepository._nextBlockLexoRank, DiaryRepository._lexoRankAfter, DiaryRepository._uuid
//  â³ Called by: GenerateFromNotesHandler.handle, SduiActionHandler._createBlock, checkAndSynthesizeForUser, ApplyMutationsHandler.handle
```

#### DiaryRepository.constructor (Function)
```rust
// Lines 22-33 (12 LOC | Complexity 3) | used by 0 callers | [MutatesState, Io, FrameworkInvoked]
constructor(dbPath?: string)
//  â³ Calls: DiaryRepository._ensureSchema
```

#### DiaryRepository._mapEntry (Function)
```rust
// Lines 492-508 (17 LOC | Complexity 3) | used by 3 callers | [Pure]
private _mapEntry(row: any): DiaryEntry
//  â³ Calls: DiaryEntry
//  â³ Called by: DiaryRepository.searchEntries, DiaryRepository.getEntry, DiaryRepository.getEntriesList
```

#### DiaryRepository.setGloballyElevated (Function)
```rust
// Lines 473-478 (6 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
setGloballyElevated(entryId: string, isGloballyElevated: boolean): void
//  â³ Calls: DiaryRepository.stmt
```

#### DiaryRepository.getModuleConfig (Function)
```rust
// Lines 689-700 (12 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getModuleConfig(userId: string, moduleId: string): Record<string, any> | null
//  â³ Calls: JbcTranslator.parse, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.getAiProviderConfig
```

#### DiaryRepository.searchEntries (Function)
```rust
// Lines 764-784 (21 LOC | Complexity 2) | used by 2 callers | [MutatesState, Io]
searchEntries(userId: string, query: string): DiaryEntry[]
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, SduiBlockRegistry.all
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, SduiActionHandler._searchDiary
```

#### DiaryRepository._nextSortOrder (Function)
```rust
// Lines 629-634 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
private _nextSortOrder(entryId: string): number
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: DiaryRepository.createBlock
```

#### DiaryRepository.getAiProviderConfig (Function)
```rust
// Lines 711-723 (13 LOC | Complexity 16) | used by 6 callers | [MutatesState, Io]
getAiProviderConfig(userId: string): Record<string, any>
//  â³ Calls: DiaryRepository.getModuleConfig
//  â³ Called by: SduiScreenAssembler._assembleDiaryAiConfig, SaveAiConfigHandler.handle, getEmbedding, SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, checkAndSynthesizeForUser
```

#### DiaryRepository.getEntryBlocks (Function)
```rust
// Lines 238-247 (10 LOC | Complexity 1) | used by 4 callers | [MutatesState, Tested]
getEntryBlocks(entryId: string): DiaryBlock[]
//  â³ Calls: DiaryBlock, DiaryRepository._mapBlock, DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, DiaryRepository.createBlock, DiaryRepository.getEntryWithBlocks, checkAndSynthesizeForUser
```

#### DiaryRepository.saveModuleConfig (Function)
```rust
// Lines 702-709 (8 LOC | Complexity 1) | used by 1 callers | [MutatesState]
saveModuleConfig(userId: string, moduleId: string, config: Record<string, any>): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SaveAiConfigHandler.handle
```

#### DiaryRepository._nextRankSuffix (Function)
```rust
// Lines 544-553 (10 LOC | Complexity 3) | used by 3 callers | [Pure]
private static _nextRankSuffix(suffix: string): string
//  â³ Called by: DiaryRepository._lexoRankAfter, DiaryRepository._nextBlockLexoRank, DiaryRepository._nextLexoRank
```

#### DiaryRepository.getBlockEmbedding (Function)
```rust
// Lines 736-744 (9 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
getBlockEmbedding(blockId: string): number[] | null
//  â³ Calls: DiaryRepository.stmt
```

#### DiaryRepository.getEntryIdForBlock (Function)
```rust
// Lines 423-428 (6 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getEntryIdForBlock(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._reorderBlock
```

#### DiaryRepository.getEntryCount (Function)
```rust
// Lines 830-835 (6 LOC | Complexity 2) | used by 0 callers | [MutatesState, PotentialDeadCode]
getEntryCount(userId: string): number
//  â³ Calls: DiaryRepository.stmt
```

#### DiaryRepository (Class)
```rust
// Lines 19-841 (823 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class DiaryRepository
//  â³ Called by: getDiaryRepository
```

#### DiaryRepository.getBlockLexoRank (Function)
```rust
// Lines 411-416 (6 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getBlockLexoRank(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: ApplyMutationsHandler.handle
```

#### DiaryRepository.stmt (Function)
```rust
// Lines 162-167 (6 LOC | Complexity 2) | used by 31 callers | [MutatesState, Io, CorePrimitive]
private stmt(name: string, sql: string): Database.Statement
//  â³ Called by: DiaryRepository.getEntryCount, DiaryRepository.getBlockEmbedding, DiaryRepository.saveBlockEmbedding, DiaryRepository.saveModuleConfig, DiaryRepository.getModuleConfig, DiaryRepository.getBlockSearchDetails, DiaryRepository._refreshPreview, DiaryRepository.getEntryUserIdForBlock, DiaryRepository._nextSortOrder, DiaryRepository._lexoRankAfter, DiaryRepository._nextBlockLexoRank, DiaryRepository._nextLexoRank, DiaryRepository.deleteEntry, DiaryRepository.setGloballyElevated, DiaryRepository.updateEntryTitle, DiaryRepository.updateEntryAnalysis, DiaryRepository.updateEntryMood, DiaryRepository.setPrivate, DiaryRepository.getEntryIdForBlock, DiaryRepository.getBlockLexoRank, DiaryRepository.reorderBlockByNeighbors, DiaryRepository.reorderBlock, DiaryRepository.deleteBlock, DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, DiaryRepository.getEntryBlocks, DiaryRepository.getMoodTimeline, DiaryRepository.getEntry, DiaryRepository.getEntriesList, ApplyMutationsHandler.handle
```

#### DiaryRepository.getEntriesList (Function)
```rust
// Lines 175-184 (10 LOC | Complexity 1) | used by 2 callers | [MutatesState, Tested]
getEntriesList(userId: string): DiaryEntry[]
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, DiaryRepository.stmt, SduiBlockRegistry.all
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, SduiActionHandler._searchDiary
```

#### DiaryRepository.deleteBlock (Function)
```rust
// Lines 324-328 (5 LOC | Complexity 1) | used by 2 callers | [MutatesState]
deleteBlock(blockId: string): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._deleteBlock, ApplyMutationsHandler.handle
```

#### DiaryRepository.getSnippetsForEntries (Function)
```rust
// Lines 797-827 (31 LOC | Complexity 5) | used by 1 callers | [MutatesState, Io, CanPanic]
getSnippetsForEntries(entryIds: string[], ftsQuery: string): Map<string, string>
//  â³ Calls: SduiStateVault.set
//  â³ Called by: SduiActionHandler._searchDiary
```

#### DiaryRepository.setPrivate (Function)
```rust
// Lines 433-438 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
setPrivate(entryId: string, isPrivate: boolean): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._setPrivate
```

#### DiaryRepository._ensureSchema (Function)
```rust
// Lines 37-155 (119 LOC | Complexity 3) | used by 1 callers | [MutatesState, Io]
private _ensureSchema(): void
//  â³ Called by: DiaryRepository.constructor
```

#### DiaryRepository.saveBlockEmbedding (Function)
```rust
// Lines 726-734 (9 LOC | Complexity 1) | used by 1 callers | [MutatesState]
saveBlockEmbedding(blockId: string, embedding: number[]): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._saveBlock
```

#### DiaryRepository.updateEntryMood (Function)
```rust
// Lines 443-448 (6 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
updateEntryMood(entryId: string, moodScore: number | null, energyScore: number | null): void
//  â³ Calls: DiaryRepository.stmt
```

#### DiaryRepository._mapBlock (Function)
```rust
// Lines 511-523 (13 LOC | Complexity 2) | used by 1 callers | [Pure]
private _mapBlock(row: any): DiaryBlock
//  â³ Calls: DiaryBlock
//  â³ Called by: DiaryRepository.getEntryBlocks
```

#### DiaryRepository._refreshPreview (Function)
```rust
// Lines 645-665 (21 LOC | Complexity 2) | used by 1 callers | [MutatesState]
private _refreshPreview(blockId: string): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: DiaryRepository.updateBlock
```

#### DiaryRepository.getEntryWithBlocks (Function)
```rust
// Lines 201-206 (6 LOC | Complexity 2) | used by 2 callers | [MutatesState]
getEntryWithBlocks(entryId: string): { entry: DiaryEntry; blocks: DiaryBlock[] } | null
//  â³ Calls: DiaryBlock, DiaryEntry, DiaryRepository.getEntryBlocks, DiaryRepository.getEntry
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor, SduiOrchestrator.sendReplacePayload
```

#### DiaryRepository.createEntry (Function)
```rust
// Lines 255-285 (31 LOC | Complexity 2) | used by 3 callers | [MutatesState]
createEntry(
//  â³ Calls: DiaryEntry, DiaryRepository.getEntry, DiaryRepository.stmt, DiaryRepository._nextLexoRank, DiaryRepository._uuid
//  â³ Called by: GenerateFromNotesHandler.handle, SduiActionHandler._createEntry, checkAndSynthesizeForUser
```

#### DiaryRepository.reorderBlockByNeighbors (Function)
```rust
// Lines 359-406 (48 LOC | Complexity 7) | used by 1 callers | [MutatesState, Io]
reorderBlockByNeighbors(
//  â³ Calls: DiaryRepository.reorderBlock, DiaryRepository._lexoRankAfter, DiaryRepository._midRankSuffix, DiaryRepository.stmt, DiaryRepository._nextBlockLexoRank
//  â³ Called by: SduiActionHandler._reorderBlock
```

#### DiaryRepository.updateEntryTitle (Function)
```rust
// Lines 463-468 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
updateEntryTitle(entryId: string, title: string): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._saveTitle
```

#### getDiaryRepository (Function)
```rust
// Lines 848-853 (6 LOC | Complexity 2) | used by 23 callers | [Pure, Tested, CorePrimitive]
function getDiaryRepository(): DiaryRepository
//  â³ Calls: DiaryRepository
//  â³ Called by: SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryList, SaveAiConfigHandler.handle, AnalysisWorker._processNext, GenerateFromNotesHandler.handle, getEmbedding, SemanticSearchHandler.handle, SduiOrchestrator.sendReplacePayload, SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, SduiActionHandler._setPrivate, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._deleteBlock, SduiActionHandler._reorderBlock, SduiActionHandler._saveBlock, SduiActionHandler._saveTitle, checkAndSynthesizeForUser, runMonthlySynthesisCheck, ApplyMutationsHandler.handle
```

#### DiaryRepository.getEntry (Function)
```rust
// Lines 189-196 (8 LOC | Complexity 1) | used by 3 callers | [MutatesState, Tested]
getEntry(entryId: string): DiaryEntry | null
//  â³ Calls: DiaryEntry, DiaryRepository._mapEntry, DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._saveTitle, DiaryRepository.createEntry, DiaryRepository.getEntryWithBlocks
```

#### DiaryRepository.updateEntryAnalysis (Function)
```rust
// Lines 453-458 (6 LOC | Complexity 1) | used by 1 callers | [MutatesState]
updateEntryAnalysis(entryId: string, moodScore: number | null, preview: string | null): void
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: AnalysisWorker._processNext
```

#### DiaryRepository._nextBlockLexoRank (Function)
```rust
// Lines 591-602 (12 LOC | Complexity 2) | used by 2 callers | [MutatesState]
private _nextBlockLexoRank(entryId: string): string
//  â³ Calls: DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.createBlock
```

#### DiaryRepository.getEntryUserIdForBlock (Function)
```rust
// Lines 636-643 (8 LOC | Complexity 2) | used by 1 callers | [MutatesState]
getEntryUserIdForBlock(blockId: string): string | null
//  â³ Calls: DiaryRepository.stmt
//  â³ Called by: SduiActionHandler._saveBlock
```

#### DiaryRepository.updateBlock (Function)
```rust
// Lines 311-319 (9 LOC | Complexity 1) | used by 4 callers | [MutatesState]
updateBlock(blockId: string, content: string): void
//  â³ Calls: DiaryRepository._refreshPreview, DiaryRepository.stmt
//  â³ Called by: GenerateFromNotesHandler.handle, SduiActionHandler._saveBlock, checkAndSynthesizeForUser, ApplyMutationsHandler.handle
```

#### DiaryRepository._lexoRankAfter (Function)
```rust
// Lines 607-627 (21 LOC | Complexity 2) | used by 3 callers | [MutatesState]
private _lexoRankAfter(entryId: string, afterRank: string): string
//  â³ Calls: DiaryRepository._midRankSuffix, DiaryRepository._nextRankSuffix, DiaryRepository.stmt
//  â³ Called by: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.createBlock, ApplyMutationsHandler.handle
```

#### DiaryRepository._uuid (Function)
```rust
// Lines 685-687 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
private _uuid(): string
//  â³ Called by: DiaryRepository.createBlock, DiaryRepository.createEntry
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\diary\diary_types.ts (53 lines)

#### DiaryListContext (Interface)
```rust
// Lines 49-63 (15 LOC | Complexity 1) | used by 0 callers
interface DiaryListContext
```

#### DiaryEditorContext (Interface)
```rust
// Lines 67-78 (12 LOC | Complexity 1) | used by 0 callers
interface DiaryEditorContext
```

#### DiaryEntry (Interface)
```rust
// Lines 8-22 (15 LOC | Complexity 1) | used by 10 callers
interface DiaryEntry
//  â³ Called by: ScoredEntry, SduiActionHandler._searchDiary, DiaryRepository.searchEntries, DiaryRepository._mapEntry, DiaryRepository.createEntry, DiaryRepository.getEntryWithBlocks, DiaryRepository.getEntry, DiaryRepository.getEntriesList, DiarySearchService.reconcile, DiarySearchService.indexEntry
```

#### DiaryBlock (Interface)
```rust
// Lines 34-44 (11 LOC | Complexity 1) | used by 6 callers
interface DiaryBlock
//  â³ Called by: DiaryRepository._mapBlock, DiaryRepository.createBlock, DiaryRepository.getEntryBlocks, DiaryRepository.getEntryWithBlocks, DiarySearchService.reconcile, DiarySearchService.indexEntry
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\gemini_jbc_provider.ts (640 lines)

#### GeminiJbcProvider.resolvePositionalRefs (Function)
```rust
// Lines 297-333 (37 LOC | Complexity 5) | used by 1 callers | [Pure, TraitMethod]
private resolvePositionalRefs(prompt: string, blocks: any[]): string
//  â³ Called by: GeminiJbcProvider.compileJbc
```

#### GeminiJbcProvider.compileJbc (Function)
```rust
// Lines 16-114 (99 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, JbcTranslator.translate, JbcTranslator.parse, AiRateLimiter.execute, SduiBlockRegistry.getSystemOwnedTypes, SduiBlockRegistry.getAiEditableTypes, JbcTranslator.serializeDiaryState, GeminiJbcProvider.resolvePositionalRefs
```

#### GeminiJbcProvider.generateSummary (Function)
```rust
// Lines 251-292 (42 LOC | Complexity 4) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
//  â³ Calls: AiRateLimiter.execute
```

#### GeminiJbcProvider.presentJbcStream (Function)
```rust
// Lines 119-246 (128 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, JbcTranslator.parse, AiRateLimiter.execute, JbcTranslator.serializeDiaryState
```

#### GeminiJbcProvider (Class)
```rust
// Lines 6-334 (329 LOC | Complexity 1) | used by 1 callers | [HighComplexity]
class GeminiJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

#### GeminiJbcProvider.constructor (Function)
```rust
// Lines 7-11 (5 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(
//  â³ Calls: AiRateLimiter
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\embeddings.ts (64 lines)

#### getEmbedding (Function)
```rust
// Lines 8-63 (56 LOC | Complexity 11) | used by 2 callers | [Async, Io]
async function getEmbedding(text: string, userId: string): Promise<number[]>
//  â³ Calls: warn, DiaryRepository.getAiProviderConfig, getDiaryRepository
//  â³ Called by: SemanticSearchHandler.handle, SduiActionHandler._saveBlock
```

#### cosineSimilarity (Function)
```rust
// Lines 68-75 (8 LOC | Complexity 3) | used by 1 callers | [Pure]
function cosineSimilarity(a: number[], b: number[]): number
//  â³ Called by: SemanticSearchHandler.handle
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_action_handler.ts (896 lines)

#### SduiActionHandler._getMonthlySynthesis (Function)
```rust
// Lines 509-527 (19 LOC | Complexity 3) | used by 1 callers | [Io]
private static _getMonthlySynthesis(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble, checkAndSynthesizeForUser
//  â³ Called by: SduiActionHandler.handle
```

#### ScoredEntry (Interface)
```rust
// Lines 360-360 (1 LOC | Complexity 1) | used by 1 callers
interface ScoredEntry { entry: DiaryEntry; score: number; }
//  â³ Calls: DiaryEntry
//  â³ Called by: SduiActionHandler._searchDiary
```

#### SduiActionHandler._deleteEntry (Function)
```rust
// Lines 262-284 (23 LOC | Complexity 5) | used by 1 callers | [Io]
private static _deleteEntry(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble, SduiDeltaEmitter.emitRemove, getDiaryRepository, DiaryRepository.deleteEntry
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._createBlock (Function)
```rust
// Lines 224-253 (30 LOC | Complexity 4) | used by 1 callers | [Io]
private static _createBlock(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble, getDiaryRepository, DiaryRepository.createBlock
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._searchDiary (Function)
```rust
// Lines 308-421 (114 LOC | Complexity 20) | used by 1 callers | [Async, Io]
private static async _searchDiary(socket: Socket, params: Record<string, any>): Promise<void>
//  â³ Calls: ScoredEntry, DiaryEntry, DiaryRepository.getBlockSearchDetails, DiaryRepository.getSnippetsForEntries, DiaryRepository.getEntriesList, SduiStateVault.set, DiaryRepository.searchEntries, DiarySearchService.getInstance, DiarySearchService.search, getDiaryRepository, SduiScreenAssembler.assemble
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler.handle (Function)
```rust
// Lines 31-82 (52 LOC | Complexity 12) | used by 1 callers | [Io]
static handle(socket: Socket, method: string, params: Record<string, any>): void
//  â³ Calls: warn, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._searchDiary, SduiActionHandler._setPrivate, SduiActionHandler._deleteEntry, SduiActionHandler._createEntry, SduiActionHandler._createBlock, SduiActionHandler._deleteBlock, SduiActionHandler._reorderBlock, SduiActionHandler._saveTitle, SduiActionHandler._saveBlock
//  â³ Called by: SduiOrchestrator.handleRpc
```

#### SduiActionHandler (Class)
```rust
// Lines 23-528 (506 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiActionHandler
```

#### SduiActionHandler._getBlocks (Function)
```rust
// Lines 484-502 (19 LOC | Complexity 3) | used by 1 callers | [Io]
private static _getBlocks(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._saveBlock (Function)
```rust
// Lines 129-149 (21 LOC | Complexity 4) | used by 1 callers | [Io]
private static _saveBlock(params: Record<string, any>): void
//  â³ Calls: DiaryRepository.saveBlockEmbedding, getEmbedding, DiaryRepository.getEntryUserIdForBlock, DiaryRepository.updateBlock, getDiaryRepository
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._saveTitle (Function)
```rust
// Lines 91-121 (31 LOC | Complexity 4) | used by 1 callers | [Io]
private static _saveTitle(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble, DiaryRepository.getEntry, SduiDeltaEmitter.emitPatch, getDiaryRepository, DiaryRepository.updateEntryTitle
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._createEntry (Function)
```rust
// Lines 430-453 (24 LOC | Complexity 4) | used by 1 callers | [Io]
private static _createEntry(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiScreenAssembler.assemble, getDiaryRepository, DiaryRepository.createEntry
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._deleteBlock (Function)
```rust
// Lines 192-206 (15 LOC | Complexity 3) | used by 1 callers | [Io]
private static _deleteBlock(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiDeltaEmitter.emitRemove, getDiaryRepository, DiaryRepository.deleteBlock
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._reorderBlock (Function)
```rust
// Lines 161-184 (24 LOC | Complexity 5) | used by 1 callers | [Io]
private static _reorderBlock(params: Record<string, any>): void
//  â³ Calls: DiaryRepository.reorderBlockByNeighbors, DiaryRepository.getEntryIdForBlock, getDiaryRepository
//  â³ Called by: SduiActionHandler.handle
```

#### SduiActionHandler._setPrivate (Function)
```rust
// Lines 461-477 (17 LOC | Complexity 3) | used by 1 callers | [Io]
private static _setPrivate(socket: Socket, params: Record<string, any>): void
//  â³ Calls: SduiDeltaEmitter.emitPatch, getDiaryRepository, DiaryRepository.setPrivate
//  â³ Called by: SduiActionHandler.handle
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_state_vault.ts (35 lines)

#### SduiStateVault.dump (Function)
```rust
// Lines 14-16 (3 LOC | Complexity 1) | used by 0 callers | [Pure, PotentialDeadCode]
public dump(): Record<string, any>
```

#### SduiStateVault.constructor (Function)
```rust
// Lines 4-4 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
constructor() {}
```

#### SduiStateVault.clear (Function)
```rust
// Lines 18-20 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
public clear(): void
//  â³ Called by: SduiBlueprintLoader.invalidateAll
```

#### SduiStateVault (Class)
```rust
// Lines 0-21 (22 LOC | Complexity 1) | used by 2 callers
class SduiStateVault
//  â³ Called by: SduiOrchestrator, SduiOrchestrator.setupListeners
```

#### SduiStateVault.set (Function)
```rust
// Lines 10-12 (3 LOC | Complexity 1) | used by 16 callers | [Pure, CorePrimitive]
public set(id: string, value: any): void
//  â³ Called by: SduiScreenAssembler._assembleDiaryList, AnalysisWorker._setStatus, SduiBlockRegistry.load, SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners, SduiOrchestrator.updateSession, SduiOrchestrator.registerHandlers, SduiBlueprintLoader.loadBlock, SduiBlueprintLoader.loadBlueprint, watchDirectoryRecursive, SduiActionHandler._searchDiary, DiaryRepository.getSnippetsForEntries, DiarySearchService.indexEntry, RadixTrie.collectAllBlockIds, RadixTrie._remove, RadixTrie._insert
```

#### SduiStateVault.get (Function)
```rust
// Lines 6-8 (3 LOC | Complexity 1) | used by 2 callers | [Pure]
public get(id: string): any
//  â³ Called by: SduiOrchestrator.handleRpc, SduiOrchestrator.setupListeners
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\jbc\jbc_translator.ts (566 lines)

#### JbcTranslator.serializeDiaryState (Function)
```rust
// Lines 288-302 (15 LOC | Complexity 5) | used by 4 callers | [Pure]
static serializeDiaryState(blocks: any[]): string
//  â³ Called by: GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc
```

#### JbcTranslator (Class)
```rust
// Lines 11-303 (293 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class JbcTranslator
```

#### JbcTranslator.parse (Function)
```rust
// Lines 199-282 (84 LOC | Complexity 18) | used by 22 callers | [MutatesState, Io, Cycle, CorePrimitive]
static parse(bytecode: string, activeBlocks?: any[]): { intent: 'MUTATE' | 'SUGGEST_TEMPLATE' | 'CONVERSE' | 'NO_OP'; mutations: JbcMutation[] }
//  â³ Calls: JbcMutation, warn, SduiBlockRegistry.isSystemOwned, JbcTranslator.resolveId, JbcTranslator.selfHealLine
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryEditor, GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, PythonSemanticsAnalyzerProvider.analyze, OllamaAnalyzerProvider.analyze, SduiBlockRegistry.buildContentNode, SduiBlockRegistry.load, SduiBlueprintLoader.loadBlock, SduiBlueprintLoader.loadBlueprint, GeminiAnalyzerProvider.analyze, DiaryRepository.getModuleConfig, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc, GeminiGeneratorProvider.generateFromNotesStream, GeminiGeneratorProvider.generateFromNotes, DiarySearchService.reconcile, DiarySearchService.indexEntry, OllamaGeneratorProvider.generateFromNotesStream, OllamaGeneratorProvider.generateFromNotes, N8nJbcProvider.presentJbcStream, ChatHandler.handle
```

#### JbcTranslator.translate (Function)
```rust
// Lines 116-193 (78 LOC | Complexity 19) | used by 3 callers | [MutatesState, Io]
static translate(bytecode: string, activeBlocks: any[]): string
//  â³ Calls: warn, SduiBlockRegistry.isSystemOwned, JbcTranslator.resolveId, JbcTranslator.selfHealLine
//  â³ Called by: GeminiJbcProvider.compileJbc, OllamaJbcProvider.compileJbc, ChatHandler.handle
```

#### JbcTranslator.resolveId (Function)
```rust
// Lines 96-109 (14 LOC | Complexity 5) | used by 2 callers | [Pure]
private static resolveId(id: string, activeBlocks?: any[]): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

#### JbcMutation (Interface)
```rust
// Lines 3-9 (7 LOC | Complexity 1) | used by 2 callers
interface JbcMutation
//  â³ Called by: JbcTranslator.parse, JbcPlanResult
```

#### JbcTranslator.selfHealLine (Function)
```rust
// Lines 16-90 (75 LOC | Complexity 22) | used by 2 callers | [Pure, HighComplexity]
private static selfHealLine(line: string): string
//  â³ Called by: JbcTranslator.parse, JbcTranslator.translate
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\utils\RadixTrie.ts (483 lines)

#### RadixTrie.constructor (Function)
```rust
// Lines 25-27 (3 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor()
//  â³ Calls: TrieNode
```

#### RadixTrie.collectAllBlockIds (Function)
```rust
// Lines 250-267 (18 LOC | Complexity 7) | used by 1 callers | [MutatesState]
private collectAllBlockIds(node: TrieNode, resultSet: Map<string, SearchMatchDetail[]>, distance: number): void
//  â³ Calls: SearchMatchDetail, TrieNode, SduiStateVault.set
//  â³ Called by: RadixTrie._fuzzySearch
```

#### RadixTrie.insert (Function)
```rust
// Lines 29-31 (3 LOC | Complexity 1) | used by 1 callers | [Pure]
public insert(tag: string, blockId: string, entryId: string): void
//  â³ Calls: RadixTrie._insert
//  â³ Called by: DiarySearchService.indexEntry
```

#### RadixTrie.remove (Function)
```rust
// Lines 93-96 (4 LOC | Complexity 1) | used by 1 callers | [MutatesState]
public remove(word: string, entryId: string, blockId?: string): boolean
//  â³ Calls: RadixTrie._remove
//  â³ Called by: DiarySearchService.removeEntry
```

#### RadixTrie._fuzzySearch (Function)
```rust
// Lines 181-248 (68 LOC | Complexity 8) | used by 1 callers | [MutatesState]
private _fuzzySearch(
//  â³ Calls: SearchMatchDetail, TrieNode, RadixTrie.collectAllBlockIds
//  â³ Called by: RadixTrie.searchWithMatches
```

#### SearchMatchDetail (Interface)
```rust
// Lines 6-10 (5 LOC | Complexity 1) | used by 4 callers
interface SearchMatchDetail
//  â³ Called by: DiarySearchService.search, RadixTrie.collectAllBlockIds, RadixTrie._fuzzySearch, RadixTrie.searchWithMatches
```

#### TrieNode (Class)
```rust
// Lines 12-20 (9 LOC | Complexity 1) | used by 6 callers
class TrieNode
//  â³ Calls: TrieEntry
//  â³ Called by: RadixTrie.collectAllBlockIds, RadixTrie._fuzzySearch, RadixTrie._remove, RadixTrie, RadixTrie._insert, RadixTrie.constructor
```

#### RadixTrie (Class)
```rust
// Lines 22-268 (247 LOC | Complexity 1) | used by 2 callers | [HighComplexity]
class RadixTrie
//  â³ Calls: TrieNode
//  â³ Called by: DiarySearchService, DiarySearchService.constructor
```

#### RadixTrie.search (Function)
```rust
// Lines 158-161 (4 LOC | Complexity 1) | used by 0 callers | [MutatesState, PotentialDeadCode]
public search(prefix: string, maxDistance: number = 2): string[]
//  â³ Calls: RadixTrie.searchWithMatches
```

#### TrieEntry (Interface)
```rust
// Lines 0-4 (5 LOC | Complexity 1) | used by 1 callers
interface TrieEntry
//  â³ Called by: TrieNode
```

#### RadixTrie.searchWithMatches (Function)
```rust
// Lines 163-179 (17 LOC | Complexity 5) | used by 2 callers | [MutatesState]
public searchWithMatches(prefix: string, maxDistance: number = 2): { [entryId: string]: SearchMatchDetail[] }
//  â³ Calls: SearchMatchDetail, RadixTrie._fuzzySearch
//  â³ Called by: DiarySearchService.search, RadixTrie.search
```

#### RadixTrie._remove (Function)
```rust
// Lines 98-156 (59 LOC | Complexity 18) | used by 1 callers | [MutatesState]
private _remove(
//  â³ Calls: TrieNode, SduiStateVault.set
//  â³ Called by: RadixTrie.remove
```

#### RadixTrie._insert (Function)
```rust
// Lines 33-69 (37 LOC | Complexity 9) | used by 1 callers | [MutatesState]
private _insert(node: TrieNode, suffix: string, blockId: string, entryId: string, fullTag: string): void
//  â³ Calls: SduiStateVault.set, TrieNode
//  â³ Called by: RadixTrie.insert
```

#### TrieNode.constructor (Function)
```rust
// Lines 16-19 (4 LOC | Complexity 1) | used by 0 callers | [MutatesState, FrameworkInvoked]
constructor()
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\providers\n8n_jbc_provider.ts (224 lines)

#### N8nJbcProvider.presentJbcStream (Function)
```rust
// Lines 45-99 (55 LOC | Complexity 11) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async *presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult, JbcTranslator.parse, N8nJbcProvider.checkConfig
```

#### N8nJbcProvider.constructor (Function)
```rust
// Lines 4-4 (1 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked, TraitMethod]
constructor(private n8nUrl: string) {}
```

#### N8nJbcProvider.generateSummary (Function)
```rust
// Lines 101-116 (16 LOC | Complexity 3) | used by 0 callers | [Async, MutatesState, Io, CanPanic, TraitMethod]
async generateSummary(entryContent: string, entryTitle: string): Promise<string>
//  â³ Calls: N8nJbcProvider.checkConfig
```

#### N8nJbcProvider (Class)
```rust
// Lines 3-117 (115 LOC | Complexity 1) | used by 1 callers
class N8nJbcProvider implements IJbcChatProvider
//  â³ Calls: IJbcChatProvider
//  â³ Called by: DiaryAiSession.create
```

#### N8nJbcProvider.compileJbc (Function)
```rust
// Lines 12-43 (32 LOC | Complexity 5) | used by 0 callers | [Async, MutatesState, Io, CanPanic, FrameworkInvoked, TraitMethod]
async compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot, N8nJbcProvider.checkConfig
```

#### N8nJbcProvider.checkConfig (Function)
```rust
// Lines 6-10 (5 LOC | Complexity 4) | used by 3 callers | [Io, CanPanic, TraitMethod]
private checkConfig()
//  â³ Called by: N8nJbcProvider.generateSummary, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\save_ai_config.ts (82 lines)

#### SaveAiConfigHandler (Class)
```rust
// Lines 6-47 (42 LOC | Complexity 1) | used by 1 callers
class SaveAiConfigHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

#### SaveAiConfigHandler.handle (Function)
```rust
// Lines 7-46 (40 LOC | Complexity 14) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, DiaryAiSession.create, SduiOrchestrator.updateSession, DiaryRepository.getAiProviderConfig, getDiaryRepository, DiaryRepository.saveModuleConfig
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\monthly_synthesis.ts (148 lines)

#### runMonthlySynthesisCheck (Function)
```rust
// Lines 26-40 (15 LOC | Complexity 2) | used by 1 callers | [Async, Io]
async function runMonthlySynthesisCheck()
//  â³ Calls: checkAndSynthesizeForUser, SduiBlockRegistry.all, getDiaryRepository
//  â³ Called by: startMonthlySynthesisLoop
```

#### checkAndSynthesizeForUser (Function)
```rust
// Lines 42-157 (116 LOC | Complexity 10) | used by 2 callers | [Async, Io]
async function checkAndSynthesizeForUser(userId: string): Promise<string | null>
//  â³ Calls: DiaryRepository.updateBlock, DiaryRepository.createBlock, DiaryRepository.createEntry, DiaryAiSession.create, DiaryRepository.getAiProviderConfig, DiaryRepository.getEntryBlocks, warn, SduiBlockRegistry.all, getDiaryRepository
//  â³ Called by: SduiActionHandler._getMonthlySynthesis, runMonthlySynthesisCheck
```

#### startMonthlySynthesisLoop (Function)
```rust
// Lines 8-24 (17 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
function startMonthlySynthesisLoop()
//  â³ Calls: runMonthlySynthesisCheck
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\handlers\analyze_entry.ts (38 lines)

#### AnalyzeEntryHandler.handle (Function)
```rust
// Lines 4-21 (18 LOC | Complexity 2) | used by 0 callers | [Async, Io, TraitMethod]
async handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext, AnalysisWorker.enqueue
```

#### AnalyzeEntryHandler (Class)
```rust
// Lines 3-22 (20 LOC | Complexity 1) | used by 1 callers
class AnalyzeEntryHandler implements ISduiRpcHandler
//  â³ Calls: ISduiRpcHandler
//  â³ Called by: SduiOrchestrator.registerHandlers
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_screen_assembler.ts (1297 lines)

#### SduiScreenAssembler.assemble (Function)
```rust
// Lines 27-62 (36 LOC | Complexity 7) | used by 8 callers | [Async, Io, Tested]
static async assemble(screenId: string, params: Record<string, any>): Promise<object | null>
//  â³ Calls: SduiScreenAssembler._assembleDiaryEditor, SduiScreenAssembler._assembleDiaryBlockPicker, SduiScreenAssembler._assembleDiaryOptionsModal, SduiScreenAssembler._assembleDiaryAiPromptModal, SduiScreenAssembler._assembleDiaryAiConfig, SduiScreenAssembler._assembleDiaryList
//  â³ Called by: SduiOrchestrator.sendReplacePayload, SduiActionHandler._getMonthlySynthesis, SduiActionHandler._getBlocks, SduiActionHandler._createEntry, SduiActionHandler._searchDiary, SduiActionHandler._deleteEntry, SduiActionHandler._createBlock, SduiActionHandler._saveTitle
```

#### SduiScreenAssembler.makeOptionRow (Function)
```rust
// Lines 555-587 (33 LOC | Complexity 1) | used by 1 callers | [Pure]
const makeOptionRow = (
//  â³ Called by: SduiScreenAssembler._assembleDiaryOptionsModal
```

#### SduiScreenAssembler.traverse (Function)
```rust
// Lines 377-386 (10 LOC | Complexity 6) | used by 1 callers | [Pure]
const traverse = (node: any) =>
//  â³ Calls: SduiScreenAssembler.filterAndTrackWrap
//  â³ Called by: SduiScreenAssembler._assembleDiaryBlockPicker
```

#### findNodeById (Function)
```rust
// Lines 668-684 (17 LOC | Complexity 11) | used by 1 callers | [Pure]
function findNodeById(node: any, id: string): any
//  â³ Called by: SduiScreenAssembler._assembleDiaryEditor
```

#### SduiScreenAssembler._assembleDiaryEditor (Function)
```rust
// Lines 199-303 (105 LOC | Complexity 16) | used by 1 callers | [Io, CanPanic]
private static _assembleDiaryEditor(entryId: string): object
//  â³ Calls: SduiBlockRegistry.buildContentNode, SduiBlockRegistry.get, SduiNodeBuilder.hydrateNode, findNodeById, JbcTranslator.parse, SduiBlueprintLoader.loadBlueprint, DiaryRepository.getEntryWithBlocks, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler.filterAndTrackWrap (Function)
```rust
// Lines 362-374 (13 LOC | Complexity 6) | used by 1 callers | [Pure]
const filterAndTrackWrap = (node: any) =>
//  â³ Called by: SduiScreenAssembler.traverse
```

#### SduiScreenAssembler._assembleDiaryBlockPicker (Function)
```rust
// Lines 341-440 (100 LOC | Complexity 14) | used by 1 callers | [Io, CanPanic]
private static _assembleDiaryBlockPicker(entryId: string, afterNodeId: string = ''): object
//  â³ Calls: SduiNodeBuilder.hydrateNode, SduiScreenAssembler.traverse, SduiBlockRegistry.all, JbcTranslator.parse, SduiBlueprintLoader.loadBlueprint
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler (Class)
```rust
// Lines 26-664 (639 LOC | Complexity 1) | used by 0 callers | [HighComplexity]
class SduiScreenAssembler
```

#### SduiScreenAssembler._assembleDiaryAiConfig (Function)
```rust
// Lines 305-326 (22 LOC | Complexity 8) | used by 1 callers | [Pure]
private static _assembleDiaryAiConfig(params: Record<string, any>): object
//  â³ Calls: SduiNodeBuilder.buildScreen, DiaryRepository.getAiProviderConfig, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler._assembleDiaryOptionsModal (Function)
```rust
// Lines 554-662 (109 LOC | Complexity 1) | used by 1 callers | [Pure]
private static _assembleDiaryOptionsModal(entryId: string): object
//  â³ Calls: SduiScreenAssembler.makeOptionRow
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler._assembleDiaryAiPromptModal (Function)
```rust
// Lines 457-539 (83 LOC | Complexity 3) | used by 1 callers | [Pure]
private static _assembleDiaryAiPromptModal(params: Record<string, any>): object
//  â³ Called by: SduiScreenAssembler.assemble
```

#### SduiScreenAssembler._assembleDiaryList (Function)
```rust
// Lines 66-195 (130 LOC | Complexity 18) | used by 1 callers | [Io, Tested]
private static _assembleDiaryList(params: Record<string, any>): object
//  â³ Calls: SduiNodeBuilder.buildScreen, SduiBlockRegistry.get, SduiStateVault.set, DiaryRepository.getMoodTimeline, DiaryRepository.searchEntries, DiarySearchService.search, DiaryRepository.getEntryBlocks, DiarySearchService.getInstance, DiarySearchService.reconcile, DiaryRepository.getEntriesList, getDiaryRepository
//  â³ Called by: SduiScreenAssembler.assemble
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_rpc_handler.ts (12 lines)

#### SduiRpcContext (Interface)
```rust
// Lines 3-10 (8 LOC | Complexity 1) | used by 9 callers
interface SduiRpcContext
//  â³ Calls: DiaryAiSession
//  â³ Called by: SaveAiConfigHandler.handle, GenerateFromNotesHandler.handle, SemanticSearchHandler.handle, GenerateSummaryHandler.handle, AnalyzeEntryHandler.handle, ApplyMutationsHandler.handle, ISduiRpcHandler.handle, RequestScreenHandler.handle, ChatHandler.handle
```

#### ISduiRpcHandler.handle (Function)
```rust
// Lines 13-13 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, PotentialDeadCode]
handle(ctx: SduiRpcContext): Promise<any>
//  â³ Calls: SduiRpcContext
```

#### ISduiRpcHandler (Interface)
```rust
// Lines 12-14 (3 LOC | Complexity 1) | used by 9 callers
interface ISduiRpcHandler
//  â³ Called by: SaveAiConfigHandler, GenerateFromNotesHandler, SemanticSearchHandler, GenerateSummaryHandler, SduiOrchestrator, AnalyzeEntryHandler, ApplyMutationsHandler, RequestScreenHandler, ChatHandler
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_analyzer.ts (11 lines)

#### AnalysisResult (Interface)
```rust
// Lines 1-7 (7 LOC | Complexity 1) | used by 6 callers
interface AnalysisResult
//  â³ Called by: AnalysisWorker._pushDelta, AnalysisWorker._processNext, PythonSemanticsAnalyzerProvider.analyze, OllamaAnalyzerProvider.analyze, GeminiAnalyzerProvider.analyze, IAnalyzerProvider.analyze
```

#### IAnalyzerProvider (Interface)
```rust
// Lines 9-11 (3 LOC | Complexity 1) | used by 7 callers
interface IAnalyzerProvider
//  â³ Called by: AnalysisWorker.constructor, PythonSemanticsAnalyzerProvider, OllamaAnalyzerProvider.constructor, OllamaAnalyzerProvider, DiaryAiSession.create, DiaryAiSession.constructor, GeminiAnalyzerProvider
```

#### IAnalyzerProvider.analyze (Function)
```rust
// Lines 10-10 (1 LOC | Complexity 1) | used by 2 callers | [Async, Pure, FrameworkInvoked]
analyze(text: string): Promise<AnalysisResult>
//  â³ Calls: AnalysisResult
//  â³ Called by: AnalysisWorker._processNext, OllamaAnalyzerProvider.analyze
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\seed_diary.ts (49 lines)

#### insertEntry (Function)
```rust
// Lines 44-69 (26 LOC | Complexity 1) | used by 1 callers | [Io]
function insertEntry(params:
//  â³ Called by: uuid
```

#### insertBlock (Function)
```rust
// Lines 72-80 (9 LOC | Complexity 2) | used by 1 callers | [Io, Cycle]
function insertBlock(entryId: string, blockType: string, content: string, rankIdx: number, codeLanguage?: string): void
//  â³ Calls: makeRank, uuid
//  â³ Called by: uuid
```

#### uuid (Function)
```rust
// Lines 26-28 (3 LOC | Complexity 1) | used by 1 callers | [Pure, Cycle]
function uuid(): string
//  â³ Calls: DiaryRepository.close, warn, insertBlock, makeRank, insertEntry, log
//  â³ Called by: insertBlock
```

#### makeRank (Function)
```rust
// Lines 31-41 (11 LOC | Complexity 2) | used by 2 callers | [Pure]
function makeRank(n: number): string
//  â³ Called by: uuid, insertBlock
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\ai\interfaces\i_jbc_chat.ts (34 lines)

#### IJbcChatProvider.presentJbcStream (Function)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 0 callers | [Pure, FrameworkInvoked]
presentJbcStream(
//  â³ Calls: DiaryStateSnapshot, JbcPlanResult
```

#### DiaryStateSnapshot (Interface)
```rust
// Lines 3-7 (5 LOC | Complexity 1) | used by 8 callers
interface DiaryStateSnapshot
//  â³ Called by: GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc, IJbcChatProvider.presentJbcStream, IJbcChatProvider.compileJbc
```

#### JbcPlanResult (Interface)
```rust
// Lines 11-16 (6 LOC | Complexity 1) | used by 8 callers
interface JbcPlanResult
//  â³ Calls: JbcMutation
//  â³ Called by: GeminiJbcProvider.presentJbcStream, GeminiJbcProvider.compileJbc, OllamaJbcProvider.presentJbcStream, OllamaJbcProvider.compileJbc, N8nJbcProvider.presentJbcStream, N8nJbcProvider.compileJbc, IJbcChatProvider.presentJbcStream, IJbcChatProvider.compileJbc
```

#### IJbcChatProvider.generateSummary (Function)
```rust
// Lines 31-31 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, PotentialDeadCode]
generateSummary(entryContent: string, entryTitle: string): Promise<string>
```

#### IJbcChatProvider (Interface)
```rust
// Lines 18-32 (15 LOC | Complexity 1) | used by 5 callers
interface IJbcChatProvider
//  â³ Called by: GeminiJbcProvider, DiaryAiSession.create, DiaryAiSession.constructor, OllamaJbcProvider, N8nJbcProvider
```

#### IJbcChatProvider.compileJbc (Function)
```rust
// Lines 20-20 (1 LOC | Complexity 1) | used by 0 callers | [Async, Pure, FrameworkInvoked]
compileJbc(prompt: string, state: DiaryStateSnapshot): Promise<JbcPlanResult>
//  â³ Calls: JbcPlanResult, DiaryStateSnapshot
```

### C:\horAIzon_2.0\shua_modules\shua_diary\src\sdui\sdui_delta_emitter.ts (95 lines)

#### SduiDeltaEmitter._emit (Function)
```rust
// Lines 83-90 (8 LOC | Complexity 2) | used by 3 callers | [Io]
private static _emit(socket: Socket, screenId: string, delta: DeltaEvent): void
//  â³ Calls: warn
//  â³ Called by: SduiDeltaEmitter.emitPatch, SduiDeltaEmitter.emitRemove, SduiDeltaEmitter.emitInsert
```

#### SduiDeltaEmitter.emitInsert (Function)
```rust
// Lines 50-53 (4 LOC | Complexity 1) | used by 0 callers | [Io, PotentialDeadCode]
static emitInsert(socket: Socket, screenId: string, node: object, afterId: string | null): void
//  â³ Calls: DeltaInsert, SduiDeltaEmitter._emit
```

#### SduiDeltaEmitter (Class)
```rust
// Lines 40-91 (52 LOC | Complexity 1) | used by 0 callers
class SduiDeltaEmitter
```

#### DeltaPatch (Interface)
```rust
// Lines 17-22 (6 LOC | Complexity 1) | used by 1 callers
interface DeltaPatch
//  â³ Called by: SduiDeltaEmitter.emitPatch
```

#### DeltaRemove (Interface)
```rust
// Lines 12-15 (4 LOC | Complexity 1) | used by 1 callers
interface DeltaRemove
//  â³ Called by: SduiDeltaEmitter.emitRemove
```

#### SduiDeltaEmitter.emitRemove (Function)
```rust
// Lines 59-62 (4 LOC | Complexity 1) | used by 2 callers | [Io]
static emitRemove(socket: Socket, screenId: string, nodeId: string): void
//  â³ Calls: DeltaRemove, SduiDeltaEmitter._emit
//  â³ Called by: SduiActionHandler._deleteEntry, SduiActionHandler._deleteBlock
```

#### DeltaInsert (Interface)
```rust
// Lines 6-10 (5 LOC | Complexity 1) | used by 1 callers
interface DeltaInsert
//  â³ Called by: SduiDeltaEmitter.emitInsert
```

#### SduiDeltaEmitter.emitPatch (Function)
```rust
// Lines 70-81 (12 LOC | Complexity 3) | used by 3 callers | [Io]
static emitPatch(
//  â³ Calls: DeltaPatch, SduiDeltaEmitter._emit
//  â³ Called by: AnalysisWorker._pushDelta, SduiActionHandler._setPrivate, SduiActionHandler._saveTitle
```


