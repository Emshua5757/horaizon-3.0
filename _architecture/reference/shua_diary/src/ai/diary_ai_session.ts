import { Socket } from 'socket.io';
import { IDiaryGeneratorProvider } from './interfaces/i_diary_generator';
import { IJbcChatProvider } from './interfaces/i_jbc_chat';
import { IAnalyzerProvider } from './interfaces/i_analyzer';
import { AnalysisWorker } from './analysis_worker';
import { AiRateLimiter } from './rate_limiter';

// Providers
import { GeminiGeneratorProvider } from './providers/gemini_generator_provider';
import { GeminiJbcProvider } from './providers/gemini_jbc_provider';
import { GeminiAnalyzerProvider } from './providers/gemini_analyzer_provider';

import { OllamaGeneratorProvider } from './providers/ollama_generator_provider';
import { OllamaJbcProvider } from './providers/ollama_jbc_provider';
import { OllamaAnalyzerProvider } from './providers/ollama_analyzer_provider';

import { PythonSemanticsAnalyzerProvider } from './providers/python_semantics_analyzer_provider';
import { N8nJbcProvider } from './providers/n8n_jbc_provider';

export interface AiProviderConfig {
  provider: 'gemini' | 'ollama' | 'python_semantics' | 'n8n';
  geminiApiKey: string;
  geminiModel: string;
  ollamaUrl: string;
  ollamaModel: string;
  n8nUrl: string;
  pythonScriptPath: string;
}

export class DiaryAiSession {
  // Shared global rate limiter instance for all Gemini calls across threads/sockets to prevent free tier rate limit errors.
  private static readonly geminiRateLimiter = new AiRateLimiter(15, 5);

  constructor(
    readonly generator: IDiaryGeneratorProvider,
    readonly jbcChat: IJbcChatProvider,
    readonly analyzer: IAnalyzerProvider,
    readonly analysisWorker: AnalysisWorker
  ) {}

  static create(config: AiProviderConfig, socket: Socket): DiaryAiSession {
    let generator: IDiaryGeneratorProvider;
    let jbcChat: IJbcChatProvider;
    let analyzer: IAnalyzerProvider;

    const providerType = config.provider || 'gemini';

    if (providerType === 'gemini') {
      generator = new GeminiGeneratorProvider(config.geminiApiKey, config.geminiModel, this.geminiRateLimiter);
      jbcChat = new GeminiJbcProvider(config.geminiApiKey, config.geminiModel, this.geminiRateLimiter);
      analyzer = new GeminiAnalyzerProvider(config.geminiApiKey, config.geminiModel, this.geminiRateLimiter);
    } else if (providerType === 'ollama') {
      generator = new OllamaGeneratorProvider(config.ollamaUrl, config.ollamaModel);
      jbcChat = new OllamaJbcProvider(config.ollamaUrl, config.ollamaModel);
      
      const fallback = new PythonSemanticsAnalyzerProvider(config.pythonScriptPath);
      analyzer = new OllamaAnalyzerProvider(config.ollamaUrl, config.ollamaModel, fallback);
    } else if (providerType === 'n8n') {
      jbcChat = new N8nJbcProvider(config.n8nUrl);
      // Fallback generator & analyzer for n8n configuration
      generator = new OllamaGeneratorProvider(config.ollamaUrl, config.ollamaModel);
      const fallback = new PythonSemanticsAnalyzerProvider(config.pythonScriptPath);
      analyzer = new OllamaAnalyzerProvider(config.ollamaUrl, config.ollamaModel, fallback);
    } else {
      // Default to Python Semantics rules-based analyser
      analyzer = new PythonSemanticsAnalyzerProvider(config.pythonScriptPath);
      generator = new OllamaGeneratorProvider(config.ollamaUrl, config.ollamaModel);
      jbcChat = new OllamaJbcProvider(config.ollamaUrl, config.ollamaModel);
    }

    const worker = new AnalysisWorker(socket, analyzer);

    return new DiaryAiSession(generator, jbcChat, analyzer, worker);
  }
}
