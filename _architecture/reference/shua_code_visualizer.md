# Repository Export

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry.rs (284 lines)

#### extract_declarations (Function)
```rust
// Lines 15-46 (32 LOC | Complexity 7) | used by 1 callers | [CanPanic]
pub fn extract_declarations(
//  â³ Calls: DeclarationExtractor, SymbolNode, AppState, Language, log_verbose
//  â³ Called by: parse_and_index_file
```

#### DeclarationExtractor (Trait)
```rust
// Lines 48-50 (3 LOC | Complexity 1) | used by 1 callers
trait DeclarationExtractor
//  â³ Calls: SymbolNode, AppState
//  â³ Called by: extract_declarations
```

#### infer_side_effects (Function)
```rust
// Lines 148-213 (66 LOC | Complexity 17) | used by 5 callers | [Async, MutatesState, Io, CanPanic]
fn infer_side_effects(source_text: &str, language: Language) -> Vec<SymbolTag>
//  â³ Calls: SymbolTag, Language
//  â³ Called by: DartExtractor::extract, PythonExtractor::extract, RustExtractor::extract, GoExtractor::extract, TypeScriptExtractor::extract
```

#### compute_cyclomatic_complexity (Function)
```rust
// Lines 52-146 (95 LOC | Complexity 22) | used by 5 callers | [MutatesState, HighComplexity]
fn compute_cyclomatic_complexity(source: &[u8], lang: Language, node: tree_sitter::Node) -> u32
//  â³ Calls: Language, walk
//  â³ Called by: DartExtractor::extract, PythonExtractor::extract, RustExtractor::extract, GoExtractor::extract, TypeScriptExtractor::extract
```

#### walk (Function)
```rust
// Lines 55-142 (88 LOC | Complexity 22) | used by 2 callers | [MutatesState, HighComplexity]
fn walk(node: tree_sitter::Node, lang: Language, source: &[u8], count: &mut u32)
//  â³ Calls: Language
//  â³ Called by: compute_cyclomatic_complexity, find_string_literal
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\scanner.rs (258 lines)

#### parse_and_index_file (Function)
```rust
// Lines 121-172 (52 LOC | Complexity 7) | used by 2 callers | [MutatesState, Io, CanPanic]
pub fn parse_and_index_file(file_path: &Path, state: &AppState)
//  â³ Calls: FileMetadata, AppState, AppState::upsert_file_symbols, extract_file_summary, extract_type_references, extract_call_sites, extract_imports, extract_declarations, detect_language
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### extract_file_summary (Function)
```rust
// Lines 174-267 (94 LOC | Complexity 30) | used by 1 callers | [MutatesState, HighComplexity]
fn extract_file_summary(source: &[u8], lang: Language) -> String
//  â³ Calls: Language
//  â³ Called by: parse_and_index_file
```

#### run_full_scan (Function)
```rust
// Lines 8-119 (112 LOC | Complexity 8) | used by 2 callers | [MutatesState, CanPanic]
pub fn run_full_scan(root: &Path, state: &AppState)
//  â³ Calls: AppState, assign_tags, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, detect_cycles, extract_api_routes, compute_centrality, resolve_edges, parse_and_index_file, log_verbose, log_status, detect_language
//  â³ Called by: main, trigger_scan
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\typescript.rs (194 lines)

#### TypeScriptExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct TypeScriptExtractor;
```

#### TypeScriptExtractor::extract (Function)
```rust
// Lines 9-201 (193 LOC | Complexity 34) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\mod.rs (12 lines)

#### ExportOptions (Struct)
```rust
// Lines 8-19 (12 LOC | Complexity 1) | used by 4 callers
pub struct ExportOptions
//  â³ Called by: serialize, serialize, serialize, export_sdg
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\public\app.js (78 lines)

#### getColor (Function)
```rust
// Lines 32-42 (11 LOC | Complexity 7) | used by 0 callers | [Pure, PotentialDeadCode]
const getColor = (d) =>
//  â³ Calls: showDetails, isConnected, drag
```

#### isConnected (Function)
```rust
// Lines 126-131 (6 LOC | Complexity 4) | used by 1 callers | [Pure]
function isConnected(a, b)
//  â³ Called by: getColor
```

#### showDetails (Function)
```rust
// Lines 171-214 (44 LOC | Complexity 3) | used by 1 callers | [Pure]
function showDetails(node, allLinks)
//  â³ Called by: getColor
```

#### drag (Function)
```rust
// Lines 152-168 (17 LOC | Complexity 3) | used by 1 callers | [Pure, FrameworkInvoked]
function drag(simulation)
//  â³ Called by: getColor
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\json.rs (78 lines)

#### serialize (Function)
```rust
// Lines 23-84 (62 LOC | Complexity 8) | used by 1 callers | [MutatesState, CanPanic]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: ExportNode, AppState, ExportOptions, SubGraph
//  â³ Called by: export_sdg
```

#### ExportNode (Struct)
```rust
// Lines 6-21 (16 LOC | Complexity 1) | used by 1 callers
pub struct ExportNode
//  â³ Called by: serialize
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\markdown.rs (80 lines)

#### serialize (Function)
```rust
// Lines 7-86 (80 LOC | Complexity 14) | used by 1 callers | [MutatesState, CanPanic]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: AppState, ExportOptions, SubGraph
//  â³ Called by: export_sdg
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\mod.rs (35 lines)

#### get_rss_mb (Function)
```rust
// Lines 34-46 (13 LOC | Complexity 4) | used by 1 callers | [Io]
fn get_rss_mb() -> u32
//  â³ Called by: health_check
```

#### health_check (Function)
```rust
// Lines 18-32 (15 LOC | Complexity 1) | used by 0 callers | [Async, CanPanic, ApiRoute]
pub async fn health_check(State(state): State<AppState>) -> Json<HealthResponse>
//  â³ Calls: HealthResponse, AppState, get_rss_mb
```

#### HealthResponse (Struct)
```rust
// Lines 10-16 (7 LOC | Complexity 1) | used by 1 callers
pub struct HealthResponse
//  â³ Called by: health_check
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\rust.rs (147 lines)

#### RustExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct RustExtractor;
```

#### RustExtractor::extract (Function)
```rust
// Lines 9-154 (146 LOC | Complexity 29) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\git_diff.rs (100 lines)

#### get_modified_files (Function)
```rust
// Lines 3-26 (24 LOC | Complexity 8) | used by 1 callers | [MutatesState]
pub fn get_modified_files(repo_root: &Path) -> Vec<PathBuf>
//  â³ Called by: export_sdg
```

#### commit_touches_file (Function)
```rust
// Lines 82-104 (23 LOC | Complexity 6) | used by 1 callers | [MutatesState]
fn commit_touches_file(repo: &Repository, commit: &Commit, file: &Path) -> bool
//  â³ Called by: churn_score
```

#### churn_score (Function)
```rust
// Lines 28-80 (53 LOC | Complexity 14) | used by 0 callers | [MutatesState, CanPanic, PotentialDeadCode]
pub fn churn_score(file: &Path, repo: &Repository, days: u32) -> f32
//  â³ Calls: commit_touches_file
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\main.rs (65 lines)

#### main (Function)
```rust
// Lines 25-89 (65 LOC | Complexity 4) | used by 0 callers | [EntryPoint, Async, CanPanic]
async fn main()
//  â³ Calls: run_full_scan, AppState::new, HbpLoggerLayer::new
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\callgraph.rs (706 lines)

#### extract_type_references (Function)
```rust
// Lines 262-333 (72 LOC | Complexity 15) | used by 1 callers | [MutatesState, CanPanic]
pub fn extract_type_references(
//  â³ Calls: AppState, Language, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

#### build_symbol_indices (Function)
```rust
// Lines 346-373 (28 LOC | Complexity 3) | used by 1 callers | [MutatesState]
fn build_symbol_indices(
//  â³ Calls: DependencyEdge, SymbolNode
//  â³ Called by: resolve_edges
```

#### resolve_edges (Function)
```rust
// Lines 335-344 (10 LOC | Complexity 1) | used by 1 callers | [CanPanic]
pub fn resolve_edges(state: &AppState)
//  â³ Calls: AppState, deduplicate_edges, resolve_type_ref_edges, resolve_call_edges, build_symbol_indices
//  â³ Called by: run_full_scan
```

#### extract_imports (Function)
```rust
// Lines 7-96 (90 LOC | Complexity 16) | used by 1 callers | [MutatesState]
pub fn extract_imports(
//  â³ Calls: ResolvedTarget, AppState, Language, resolve_import, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

#### find_first_string_literal_in_ancestor (Function)
```rust
// Lines 242-259 (18 LOC | Complexity 5) | used by 1 callers | [MutatesState]
fn find_first_string_literal_in_ancestor(node: tree_sitter::Node, source: &[u8]) -> Option<String>
//  â³ Calls: find_string_literal
//  â³ Called by: extract_call_sites
```

#### deduplicate_edges (Function)
```rust
// Lines 665-690 (26 LOC | Complexity 4) | used by 1 callers | [MutatesState, CanPanic]
fn deduplicate_edges(state: &AppState)
//  â³ Calls: AppState, log_verbose
//  â³ Called by: resolve_edges
```

#### resolve_call_edges (Function)
```rust
// Lines 375-548 (174 LOC | Complexity 39) | used by 1 callers | [MutatesState, CanPanic, HighComplexity]
fn resolve_call_edges(
//  â³ Calls: DependencyEdge, AppState, log_verbose
//  â³ Called by: resolve_edges
```

#### resolve_type_ref_edges (Function)
```rust
// Lines 550-663 (114 LOC | Complexity 29) | used by 1 callers | [MutatesState, CanPanic, HighComplexity]
fn resolve_type_ref_edges(
//  â³ Calls: DependencyEdge, AppState, log_verbose
//  â³ Called by: resolve_edges
```

#### test_dart_method_call_ast (Function)
```rust
// Lines 699-731 (33 LOC | Complexity 3) | used by 0 callers | [MutatesState, CanPanic]
fn test_dart_method_call_ast()
//  â³ Calls: get_tree_sitter_language, get_parser
```

#### find_string_literal (Function)
```rust
// Lines 226-240 (15 LOC | Complexity 5) | used by 1 callers | [MutatesState]
fn find_string_literal(node: tree_sitter::Node, source: &[u8]) -> Option<String>
//  â³ Calls: walk
//  â³ Called by: find_first_string_literal_in_ancestor
```

#### extract_call_sites (Function)
```rust
// Lines 99-224 (126 LOC | Complexity 17) | used by 1 callers | [MutatesState, CanPanic]
pub fn extract_call_sites(
//  â³ Calls: AppState, Language, find_first_string_literal_in_ancestor, get_tree_sitter_language, get_parser
//  â³ Called by: parse_and_index_file
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\analyzer.rs (645 lines)

#### assign_tags (Function)
```rust
// Lines 497-573 (77 LOC | Complexity 8) | used by 3 callers | [MutatesState, CanPanic]
pub fn assign_tags(state: &AppState)
//  â³ Calls: AppState, log_verbose, detect_test_linkages
//  â³ Called by: debug_analysis, test_regression_hardening, run_full_scan
```

#### detect_serde_callbacks (Function)
```rust
// Lines 333-407 (75 LOC | Complexity 22) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_serde_callbacks(state: &AppState)
//  â³ Calls: AppState, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### detect_cycles (Function)
```rust
// Lines 19-59 (41 LOC | Complexity 12) | used by 2 callers | [MutatesState, CanPanic]
pub fn detect_cycles(state: &AppState)
//  â³ Calls: AppState
//  â³ Called by: debug_analysis, run_full_scan
```

#### detect_entry_points (Function)
```rust
// Lines 409-426 (18 LOC | Complexity 5) | used by 2 callers | [MutatesState, CanPanic]
pub fn detect_entry_points(state: &AppState)
//  â³ Calls: AppState, log_verbose
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### detect_framework_invoked (Function)
```rust
// Lines 133-331 (199 LOC | Complexity 44) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_framework_invoked(state: &AppState)
//  â³ Calls: AppState, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### detect_trait_method_impls (Function)
```rust
// Lines 61-131 (71 LOC | Complexity 21) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn detect_trait_method_impls(state: &AppState)
//  â³ Calls: AppState, get_tree_sitter_language, get_parser
//  â³ Called by: test_regression_hardening, run_full_scan
```

#### test_regression_hardening (Function)
```rust
// Lines 583-664 (82 LOC | Complexity 6) | used by 0 callers | [MutatesState, Io, CanPanic]
fn test_regression_hardening()
//  â³ Calls: assign_tags, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, parse_and_index_file, AppState::new
```

#### detect_test_linkages (Function)
```rust
// Lines 428-495 (68 LOC | Complexity 17) | used by 1 callers | [MutatesState, Io, CanPanic]
pub fn detect_test_linkages(state: &AppState)
//  â³ Calls: AppState, log_verbose
//  â³ Called by: assign_tags
```

#### compute_centrality (Function)
```rust
// Lines 4-17 (14 LOC | Complexity 3) | used by 2 callers | [MutatesState, CanPanic]
pub fn compute_centrality(state: &AppState)
//  â³ Calls: AppState
//  â³ Called by: debug_analysis, run_full_scan
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\boundary.rs (53 lines)

#### get_module_root (Function)
```rust
// Lines 9-18 (10 LOC | Complexity 6) | used by 1 callers | [MutatesState]
fn get_module_root(path: &Path) -> Option<String>
//  â³ Called by: find_boundary_violations
```

#### BoundaryViolation (Struct)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 2 callers
pub struct BoundaryViolation
//  â³ Called by: DebugReport, find_boundary_violations
```

#### find_boundary_violations (Function)
```rust
// Lines 20-58 (39 LOC | Complexity 6) | used by 1 callers | [MutatesState, CanPanic]
pub fn find_boundary_violations(state: &AppState) -> Vec<BoundaryViolation>
//  â³ Calls: BoundaryViolation, AppState, get_module_root
//  â³ Called by: debug_analysis
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\scan.rs (41 lines)

#### ScanResponse (Struct)
```rust
// Lines 12-15 (4 LOC | Complexity 1) | used by 1 callers
pub struct ScanResponse
//  â³ Called by: trigger_scan
```

#### ScanRequest (Struct)
```rust
// Lines 7-9 (3 LOC | Complexity 1) | used by 1 callers
pub struct ScanRequest
//  â³ Called by: trigger_scan
```

#### trigger_scan (Function)
```rust
// Lines 17-50 (34 LOC | Complexity 2) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn trigger_scan(
//  â³ Calls: ScanResponse, ScanRequest, AppState, run_full_scan
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\python.rs (128 lines)

#### PythonExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct PythonExtractor;
```

#### PythonExtractor::extract (Function)
```rust
// Lines 9-135 (127 LOC | Complexity 25) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\logging.rs (201 lines)

#### HbpLoggerLayer (Struct)
```rust
// Lines 16-18 (3 LOC | Complexity 1) | used by 0 callers
pub struct HbpLoggerLayer
//  â³ Calls: HbpLoggerLayer::new
```

#### FieldVisitor (Struct)
```rust
// Lines 32-35 (4 LOC | Complexity 1) | used by 1 callers
struct FieldVisitor
//  â³ Called by: HbpLoggerLayer::on_event
```

#### FieldVisitor::record_i64 (Function)
```rust
// Lines 59-61 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_i64(&mut self, field: &tracing::field::Field, value: i64)
```

#### log_verbose (Function)
```rust
// Lines 202-212 (11 LOC | Complexity 3) | used by 9 callers | [Io]
pub fn log_verbose(subsystem: &str, message: &str)
//  â³ Called by: extract_declarations, assign_tags, detect_test_linkages, detect_entry_points, resolve_import, run_full_scan, deduplicate_edges, resolve_type_ref_edges, resolve_call_edges
```

#### HbpLoggerLayer::HbpLogMsgpack (Struct)
```rust
// Lines 134-156 (23 LOC | Complexity 1) | used by 1 callers | [TraitMethod]
struct HbpLogMsgpack
//  â³ Called by: HbpLoggerLayer::on_event
```

#### FieldVisitor::record_bool (Function)
```rust
// Lines 63-65 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_bool(&mut self, field: &tracing::field::Field, value: bool)
```

#### FieldVisitor::record_debug (Function)
```rust
// Lines 38-45 (8 LOC | Complexity 2) | used by 0 callers | [TraitMethod, MutatesState]
fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug)
```

#### HbpLoggerLayer::new (Function)
```rust
// Lines 21-28 (8 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
pub fn new() -> Self
//  â³ Called by: main, HbpLoggerLayer::on_event, HbpLoggerLayer
```

#### log_status (Function)
```rust
// Lines 193-200 (8 LOC | Complexity 2) | used by 1 callers | [Io]
pub fn log_status(subsystem: &str, message: &str)
//  â³ Called by: run_full_scan
```

#### FieldVisitor::record_u64 (Function)
```rust
// Lines 55-57 (3 LOC | Complexity 1) | used by 0 callers | [TraitMethod, MutatesState]
fn record_u64(&mut self, field: &tracing::field::Field, value: u64)
```

#### map_level (Function)
```rust
// Lines 69-77 (9 LOC | Complexity 6) | used by 1 callers | [Pure]
fn map_level(level: &Level) -> u8
//  â³ Called by: HbpLoggerLayer::on_event
```

#### HbpLoggerLayer::on_event (Function)
```rust
// Lines 80-190 (111 LOC | Complexity 5) | used by 0 callers | [TraitMethod, MutatesState, Io]
fn on_event(&self, event: &Event<'_>, _ctx: Context<'_, S>)
//  â³ Calls: HbpLoggerLayer::HbpLogMsgpack, FieldVisitor, HbpLoggerLayer::new, map_level
```

#### FieldVisitor::record_str (Function)
```rust
// Lines 47-53 (7 LOC | Complexity 2) | used by 0 callers | [TraitMethod, MutatesState]
fn record_str(&mut self, field: &tracing::field::Field, value: &str)
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\trait_map.rs (76 lines)

#### extract_trait_map (Function)
```rust
// Lines 9-81 (73 LOC | Complexity 19) | used by 1 callers | [MutatesState, Io, CanPanic]
pub fn extract_trait_map(state: &AppState) -> TraitMap
//  â³ Calls: TraitMap, AppState, get_parser, detect_language
//  â³ Called by: debug_analysis
```

#### TraitMap (Struct)
```rust
// Lines 5-7 (3 LOC | Complexity 1) | used by 2 callers
pub struct TraitMap
//  â³ Called by: DebugReport, extract_trait_map
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\graph\store.rs (137 lines)

#### DependencyType (Enum)
```rust
// Lines 27-32 (6 LOC | Complexity 1) | used by 1 callers
pub enum DependencyType
//  â³ Called by: DependencyEdge
```

#### AppState::upsert_file_symbols (Function)
```rust
// Lines 116-167 (52 LOC | Complexity 9) | used by 1 callers | [MutatesState, CanPanic, TraitMethod]
pub fn upsert_file_symbols(
//  â³ Calls: DependencyEdge, SymbolNode, AppState::new
//  â³ Called by: parse_and_index_file
```

#### SymbolNode (Struct)
```rust
// Lines 63-80 (18 LOC | Complexity 1) | used by 10 callers
pub struct SymbolNode
//  â³ Calls: Language, SymbolTag, Visibility, SymbolKind
//  â³ Called by: DeclarationExtractor, extract_declarations, DartExtractor::extract, PythonExtractor::extract, AppState::upsert_file_symbols, AppState, RustExtractor::extract, GoExtractor::extract, build_symbol_indices, TypeScriptExtractor::extract
```

#### DependencyEdge (Struct)
```rust
// Lines 83-86 (4 LOC | Complexity 1) | used by 5 callers
pub struct DependencyEdge
//  â³ Calls: DependencyType
//  â³ Called by: AppState::upsert_file_symbols, AppState, resolve_type_ref_edges, resolve_call_edges, build_symbol_indices
```

#### SymbolKind (Enum)
```rust
// Lines 10-18 (9 LOC | Complexity 1) | used by 1 callers
pub enum SymbolKind
//  â³ Called by: SymbolNode
```

#### Visibility (Enum)
```rust
// Lines 21-24 (4 LOC | Complexity 1) | used by 1 callers
pub enum Visibility
//  â³ Called by: SymbolNode
```

#### SymbolTag (Enum)
```rust
// Lines 35-51 (17 LOC | Complexity 1) | used by 2 callers
pub enum SymbolTag
//  â³ Called by: infer_side_effects, SymbolNode
```

#### Language (Enum)
```rust
// Lines 54-60 (7 LOC | Complexity 1) | used by 13 callers | [CorePrimitive]
pub enum Language
//  â³ Called by: infer_side_effects, walk, compute_cyclomatic_complexity, extract_declarations, resolve_import, extract_file_summary, SymbolNode, get_parser, get_tree_sitter_language, detect_language, extract_type_references, extract_call_sites, extract_imports
```

#### AppState (Struct)
```rust
// Lines 97-102 (6 LOC | Complexity 1) | used by 38 callers | [CorePrimitive]
pub struct AppState
//  â³ Calls: FileMetadata, DependencyEdge, SymbolNode
//  â³ Called by: get_graph, debug_analysis, DeclarationExtractor, extract_declarations, DartExtractor::extract, assign_tags, detect_test_linkages, detect_entry_points, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, detect_cycles, compute_centrality, PythonExtractor::extract, health_check, serialize, serialize, parse_and_index_file, run_full_scan, RustExtractor::extract, compute_subgraph, trigger_scan, serialize, GoExtractor::extract, search_bm25, extract_trait_map, extract_api_routes, deduplicate_edges, resolve_type_ref_edges, resolve_call_edges, resolve_edges, extract_type_references, extract_call_sites, extract_imports, TypeScriptExtractor::extract, find_boundary_violations, find_ghost_imports, export_sdg
```

#### AppState::new (Function)
```rust
// Lines 105-112 (8 LOC | Complexity 1) | used by 3 callers | [Pure, TraitMethod]
pub fn new() -> Self
//  â³ Called by: test_regression_hardening, main, AppState::upsert_file_symbols
```

#### FileMetadata (Struct)
```rust
// Lines 89-94 (6 LOC | Complexity 1) | used by 2 callers
pub struct FileMetadata
//  â³ Called by: parse_and_index_file, AppState
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\dart.rs (159 lines)

#### DartExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct DartExtractor;
```

#### DartExtractor::extract (Function)
```rust
// Lines 9-166 (158 LOC | Complexity 28) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\ast.rs (32 lines)

#### detect_language (Function)
```rust
// Lines 8-18 (11 LOC | Complexity 9) | used by 4 callers | [Pure]
pub fn detect_language(path: &Path) -> Option<Language>
//  â³ Calls: Language
//  â³ Called by: parse_and_index_file, run_full_scan, extract_trait_map, extract_api_routes
```

#### get_parser (Function)
```rust
// Lines 33-41 (9 LOC | Complexity 2) | used by 14 callers | [MutatesState, CorePrimitive]
pub fn get_parser(lang: Language) -> Option<Parser>
//  â³ Calls: Language, get_tree_sitter_language
//  â³ Called by: DartExtractor::extract, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, PythonExtractor::extract, RustExtractor::extract, GoExtractor::extract, extract_trait_map, extract_api_routes, test_dart_method_call_ast, extract_type_references, extract_call_sites, extract_imports, TypeScriptExtractor::extract
```

#### get_tree_sitter_language (Function)
```rust
// Lines 20-31 (12 LOC | Complexity 6) | used by 13 callers | [Pure, CorePrimitive]
pub fn get_tree_sitter_language(lang: Language) -> tree_sitter::Language
//  â³ Calls: Language
//  â³ Called by: DartExtractor::extract, detect_serde_callbacks, detect_framework_invoked, detect_trait_method_impls, PythonExtractor::extract, RustExtractor::extract, GoExtractor::extract, get_parser, test_dart_method_call_ast, extract_type_references, extract_call_sites, extract_imports, TypeScriptExtractor::extract
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\xml.rs (140 lines)

#### serialize (Function)
```rust
// Lines 7-146 (140 LOC | Complexity 23) | used by 1 callers | [MutatesState, CanPanic, HighComplexity]
pub fn serialize(subgraph: &SubGraph, opts: &ExportOptions, state: &AppState) -> String
//  â³ Calls: AppState, ExportOptions, SubGraph
//  â³ Called by: export_sdg
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\ghost_imports.rs (46 lines)

#### GhostImportReport (Struct)
```rust
// Lines 4-8 (5 LOC | Complexity 1) | used by 2 callers
pub struct GhostImportReport
//  â³ Called by: DebugReport, find_ghost_imports
```

#### find_ghost_imports (Function)
```rust
// Lines 10-50 (41 LOC | Complexity 8) | used by 1 callers | [MutatesState, CanPanic]
pub fn find_ghost_imports(state: &AppState) -> Vec<GhostImportReport>
//  â³ Calls: GhostImportReport, AppState
//  â³ Called by: debug_analysis
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\search.rs (85 lines)

#### SearchResult (Struct)
```rust
// Lines 4-7 (4 LOC | Complexity 1) | used by 1 callers
pub struct SearchResult
//  â³ Called by: search_bm25
```

#### search_bm25 (Function)
```rust
// Lines 9-89 (81 LOC | Complexity 11) | used by 1 callers | [MutatesState, CanPanic]
pub fn search_bm25(query: &str, state: &AppState) -> Vec<SearchResult>
//  â³ Calls: SearchResult, AppState
//  â³ Called by: export_sdg
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\graph.rs (77 lines)

#### GraphPayload (Struct)
```rust
// Lines 31-34 (4 LOC | Complexity 1) | used by 1 callers
pub struct GraphPayload
//  â³ Calls: GraphLink, GraphNode
//  â³ Called by: get_graph
```

#### get_graph (Function)
```rust
// Lines 36-86 (51 LOC | Complexity 7) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute]
pub async fn get_graph(State(state): State<AppState>) -> Json<GraphPayload>
//  â³ Calls: GraphLink, GraphNode, GraphPayload, AppState
```

#### GraphLink (Struct)
```rust
// Lines 23-28 (6 LOC | Complexity 1) | used by 2 callers
pub struct GraphLink
//  â³ Called by: get_graph, GraphPayload
```

#### GraphNode (Struct)
```rust
// Lines 5-20 (16 LOC | Complexity 1) | used by 2 callers
pub struct GraphNode
//  â³ Called by: get_graph, GraphPayload
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\lexer.rs (5 lines)

#### Lexer (Struct)
```rust
// Lines 0-0 (1 LOC | Complexity 1) | used by 0 callers
pub struct Lexer;
```

#### Lexer::parse_imports (Function)
```rust
// Lines 3-6 (4 LOC | Complexity 1) | used by 0 callers | [Pure, TraitMethod]
pub fn parse_imports(_content: &str, _language: &str) -> Vec<String>
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\debug\routes_map.rs (185 lines)

#### RouteNode (Struct)
```rust
// Lines 17-22 (6 LOC | Complexity 1) | used by 2 callers
pub struct RouteNode
//  â³ Calls: HttpMethod
//  â³ Called by: DebugReport, extract_api_routes
```

#### HttpMethod (Enum)
```rust
// Lines 7-14 (8 LOC | Complexity 1) | used by 1 callers
pub enum HttpMethod
//  â³ Called by: RouteNode
```

#### extract_api_routes (Function)
```rust
// Lines 24-194 (171 LOC | Complexity 43) | used by 2 callers | [MutatesState, Io, CanPanic, HighComplexity]
pub fn extract_api_routes(state: &AppState) -> Vec<RouteNode>
//  â³ Calls: RouteNode, AppState, get_parser, detect_language
//  â³ Called by: debug_analysis, run_full_scan
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\export.rs (94 lines)

#### export_sdg (Function)
```rust
// Lines 11-104 (94 LOC | Complexity 17) | used by 0 callers | [Async, MutatesState, CanPanic, ApiRoute]
pub async fn export_sdg(
//  â³ Calls: SubGraph, ExportOptions, AppState, serialize, serialize, serialize, compute_subgraph, get_modified_files, search_bm25
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\export\blast_radius.rs (52 lines)

#### compute_subgraph (Function)
```rust
// Lines 10-57 (48 LOC | Complexity 13) | used by 1 callers | [MutatesState, CanPanic]
pub fn compute_subgraph(focus_name: &str, depth: usize, state: &AppState) -> SubGraph
//  â³ Calls: SubGraph, AppState
//  â³ Called by: export_sdg
```

#### SubGraph (Struct)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 5 callers
pub struct SubGraph
//  â³ Called by: serialize, serialize, compute_subgraph, serialize, export_sdg
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\registry\go.rs (154 lines)

#### GoExtractor (Struct)
```rust
// Lines 6-6 (1 LOC | Complexity 1) | used by 0 callers
pub struct GoExtractor;
```

#### GoExtractor::extract (Function)
```rust
// Lines 9-161 (153 LOC | Complexity 28) | used by 0 callers | [TraitMethod, MutatesState, CanPanic, HighComplexity]
fn extract(&self, file: &Path, source: &[u8], state: &AppState) -> Vec<SymbolNode>
//  â³ Calls: SymbolNode, AppState, infer_side_effects, compute_cyclomatic_complexity, get_tree_sitter_language, get_parser
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\parser\resolver.rs (90 lines)

#### ResolvedTarget (Enum)
```rust
// Lines 5-8 (4 LOC | Complexity 1) | used by 2 callers
pub enum ResolvedTarget
//  â³ Called by: resolve_import, extract_imports
```

#### clean_path (Function)
```rust
// Lines 11-26 (16 LOC | Complexity 5) | used by 1 callers | [MutatesState]
pub fn clean_path(path: &Path) -> PathBuf
//  â³ Called by: resolve_import
```

#### resolve_import (Function)
```rust
// Lines 28-97 (70 LOC | Complexity 19) | used by 1 callers | [MutatesState]
pub fn resolve_import(source_file: &Path, raw_target: &str, lang: Language) -> ResolvedTarget
//  â³ Calls: ResolvedTarget, Language, log_verbose, clean_path
//  â³ Called by: extract_imports
```

### C:\horAIzon_2.0\shua_modules\shua_code_visualizer\src\routes\debug.rs (25 lines)

#### DebugReport (Struct)
```rust
// Lines 9-14 (6 LOC | Complexity 1) | used by 1 callers
pub struct DebugReport
//  â³ Calls: TraitMap, RouteNode, BoundaryViolation, GhostImportReport
//  â³ Called by: debug_analysis
```

#### debug_analysis (Function)
```rust
// Lines 16-34 (19 LOC | Complexity 1) | used by 0 callers | [Async, Pure, ApiRoute]
pub async fn debug_analysis(State(state): State<AppState>) -> Json<DebugReport>
//  â³ Calls: DebugReport, AppState, extract_trait_map, extract_api_routes, find_boundary_violations, find_ghost_imports, assign_tags, detect_cycles, compute_centrality
```


