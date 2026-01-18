/**
 * Model Watcher - Consumer Watcher for App Integration
 *
 * This module watches the models/stable/ directory for new model arrivals.
 * It triggers a reload event ONLY when a new sub-directory appears.
 *
 * Enforces the Law of Hardware Fidelity:
 * - If a model is tagged 'mps' and runtime is 'cpu', it logs a CRITICAL error
 *   and refuses to load the model. No silent fallbacks allowed.
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { EventEmitter } from 'events';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const MODELS_STABLE_DIR = path.resolve(__dirname, '../../models/stable');
const POLL_INTERVAL_MS = 5000; // Check every 5 seconds

// Detect runtime hardware
function detectHardware(): string {
    // In a real scenario, you'd detect GPU availability
    // For now, default to 'cpu' in Node.js environment
    if (process.platform === 'darwin') {
        // Could be MPS on Apple Silicon, but Node.js doesn't have native MPS
        return 'cpu'; // Node.js inference typically uses CPU
    }
    return 'cpu';
}

const RUNTIME_HARDWARE = detectHardware();

interface ModelMetadata {
    model_id: string;
    git_hash: string;
    framework: string;
    min_app_version: string;
    required_hardware: string;
    metrics?: Record<string, number>;
    notes?: string;
    dataset_fingerprint?: string;
}

interface LoadedModel {
    id: string;
    path: string;
    metadata: ModelMetadata;
    loadedAt: Date;
}

export class ModelWatcher extends EventEmitter {
    private knownModels: Set<string> = new Set();
    private loadedModels: Map<string, LoadedModel> = new Map();
    private pollTimer: NodeJS.Timeout | null = null;
    private isRunning: boolean = false;

    constructor() {
        super();
        console.log(`[ModelWatcher] Runtime hardware detected: ${RUNTIME_HARDWARE}`);
    }

    /**
     * Start watching the models/stable directory
     */
    start(): void {
        if (this.isRunning) {
            console.warn('[ModelWatcher] Already running');
            return;
        }

        console.log(`[ModelWatcher] Starting watch on: ${MODELS_STABLE_DIR}`);
        this.isRunning = true;

        // Ensure directory exists
        if (!fs.existsSync(MODELS_STABLE_DIR)) {
            fs.mkdirSync(MODELS_STABLE_DIR, { recursive: true });
            console.log(`[ModelWatcher] Created directory: ${MODELS_STABLE_DIR}`);
        }

        // Initial scan
        this.scanForNewModels();

        // Start polling
        this.pollTimer = setInterval(() => {
            this.scanForNewModels();
        }, POLL_INTERVAL_MS);

        console.log(`[ModelWatcher] Polling every ${POLL_INTERVAL_MS}ms`);
    }

    /**
     * Stop watching
     */
    stop(): void {
        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }
        this.isRunning = false;
        console.log('[ModelWatcher] Stopped');
    }

    /**
     * Scan for new model directories
     */
    private scanForNewModels(): void {
        try {
            const entries = fs.readdirSync(MODELS_STABLE_DIR, { withFileTypes: true });
            const currentDirs = new Set<string>();

            for (const entry of entries) {
                if (entry.isDirectory()) {
                    currentDirs.add(entry.name);

                    // Check if this is a new model
                    if (!this.knownModels.has(entry.name)) {
                        console.log(`[ModelWatcher] 🆕 New model detected: ${entry.name}`);
                        this.knownModels.add(entry.name);
                        this.handleNewModel(entry.name);
                    }
                }
            }

            // Note: We don't remove models from knownModels (Law of Immutability)
            // Once a model is in stable/, it should never be deleted

        } catch (error) {
            if ((error as NodeJS.ErrnoException).code !== 'ENOENT') {
                console.error('[ModelWatcher] Error scanning directory:', error);
            }
        }
    }

    /**
     * Handle a newly detected model
     */
    private handleNewModel(modelId: string): void {
        const modelPath = path.join(MODELS_STABLE_DIR, modelId);
        const metadataPath = path.join(modelPath, 'metadata.yaml');

        // Check for metadata.yaml
        if (!fs.existsSync(metadataPath)) {
            console.error(`[ModelWatcher] ❌ CRITICAL: No metadata.yaml found for ${modelId}`);
            this.emit('error', { modelId, error: 'MISSING_METADATA' });
            return;
        }

        // Parse metadata (simple YAML parsing for basic cases)
        const metadata = this.parseMetadata(metadataPath);
        if (!metadata) {
            console.error(`[ModelWatcher] ❌ CRITICAL: Failed to parse metadata for ${modelId}`);
            this.emit('error', { modelId, error: 'INVALID_METADATA' });
            return;
        }

        // ═══════════════════════════════════════════════════════════════════
        // LAW OF HARDWARE FIDELITY
        // ═══════════════════════════════════════════════════════════════════
        if (metadata.required_hardware === 'mps' && RUNTIME_HARDWARE === 'cpu') {
            console.error(`[ModelWatcher] ❌ CRITICAL: Model '${modelId}' requires MPS but runtime is CPU`);
            console.error(`[ModelWatcher]    The Law of Hardware Fidelity prevents loading this model.`);
            console.error(`[ModelWatcher]    NO SILENT FALLBACKS ALLOWED.`);
            this.emit('error', {
                modelId,
                error: 'HARDWARE_MISMATCH',
                required: 'mps',
                available: RUNTIME_HARDWARE
            });
            return;
        }

        if (metadata.required_hardware === 'cuda' && RUNTIME_HARDWARE !== 'cuda') {
            console.error(`[ModelWatcher] ❌ CRITICAL: Model '${modelId}' requires CUDA but runtime is ${RUNTIME_HARDWARE}`);
            console.error(`[ModelWatcher]    The Law of Hardware Fidelity prevents loading this model.`);
            this.emit('error', {
                modelId,
                error: 'HARDWARE_MISMATCH',
                required: 'cuda',
                available: RUNTIME_HARDWARE
            });
            return;
        }

        // Model is valid and hardware-compatible
        const loadedModel: LoadedModel = {
            id: modelId,
            path: modelPath,
            metadata,
            loadedAt: new Date()
        };

        this.loadedModels.set(modelId, loadedModel);

        console.log(`[ModelWatcher] ✅ Model '${modelId}' loaded successfully`);
        console.log(`[ModelWatcher]    Framework: ${metadata.framework}`);
        console.log(`[ModelWatcher]    Hardware: ${metadata.required_hardware}`);
        console.log(`[ModelWatcher]    Min App Version: ${metadata.min_app_version}`);

        // Emit reload event for consumers
        this.emit('model-loaded', loadedModel);
    }

    /**
     * Simple YAML parser for metadata files
     * (In production, use a proper YAML library)
     */
    private parseMetadata(filePath: string): ModelMetadata | null {
        try {
            const content = fs.readFileSync(filePath, 'utf-8');
            const metadata: Partial<ModelMetadata> = {};

            // Simple line-by-line parsing
            const lines = content.split('\n');
            for (const line of lines) {
                const match = line.match(/^(\w+):\s*(.+)$/);
                if (match) {
                    const [, key, value] = match;
                    (metadata as Record<string, string>)[key] = value.trim();
                }
            }

            // Validate required fields
            const required = ['model_id', 'git_hash', 'framework', 'min_app_version', 'required_hardware'];
            for (const field of required) {
                if (!(field in metadata)) {
                    console.error(`[ModelWatcher] Missing required field: ${field}`);
                    return null;
                }
            }

            return metadata as ModelMetadata;
        } catch (error) {
            console.error('[ModelWatcher] Error reading metadata:', error);
            return null;
        }
    }

    /**
     * Get all currently loaded models
     */
    getLoadedModels(): LoadedModel[] {
        return Array.from(this.loadedModels.values());
    }

    /**
     * Get a specific loaded model by ID
     */
    getModel(modelId: string): LoadedModel | undefined {
        return this.loadedModels.get(modelId);
    }
}

// Export singleton instance
export const modelWatcher = new ModelWatcher();
