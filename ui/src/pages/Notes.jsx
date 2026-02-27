import { useState, useEffect } from 'react';
import api from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import NoteCard from '../components/NoteCard';
import './NotesDashboard.css'; // New dedicated styles
import '../App.css';

const Notes = () => {
    const { isLoading: authLoading } = useAuth();
    const [notes, setNotes] = useState([]);
    const [allTags, setAllTags] = useState([]);
    const [title, setTitle] = useState('');
    const [content, setContent] = useState('');
    const [tags, setTags] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedTag, setSelectedTag] = useState(null);
    const [selectedNote, setSelectedNote] = useState(null);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [editTitle, setEditTitle] = useState('');
    const [editContent, setEditContent] = useState('');
    const [editTags, setEditTags] = useState('');
    const [analyzingNotes, setAnalyzingNotes] = useState({}); // { noteId: true/false }

    useEffect(() => {
        if (!authLoading) {
            fetchNotes();
            fetchAllTags();
        }
    }, [searchQuery, selectedTag, authLoading]);

    const fetchNotes = async () => {
        try {
            const params = {};
            if (searchQuery) params.q = searchQuery;
            if (selectedTag) params.tag = selectedTag;
            const response = await api.get('/notes', { params });
            setNotes(response.data);
        } catch (error) {
            console.error('Error fetching notes:', error);
        }
    };

    const fetchAllTags = async () => {
        try {
            const response = await api.get('/tags');
            setAllTags(Array.isArray(response.data) ? response.data : []);
        } catch (error) {
            console.error('Error fetching tags:', error);
            setAllTags([]);
        }
    };

    const createNote = async (e) => {
        e.preventDefault();
        try {
            const tagsList = tags.split(',').map(t => t.trim()).filter(t => t);
            await api.post('/notes', { title, content, tags: tagsList });
            setTitle('');
            setContent('');
            setTags('');
            fetchNotes();
            fetchAllTags();
        } catch (error) {
            console.error('Error creating note:', error);
        }
    };

    const openNote = (note) => {
        setSelectedNote(note);
        setEditTitle(note.title);
        setEditContent(note.content);
        const tagString = note.tags ? note.tags.map(t => t.name).join(', ') : '';
        setEditTags(tagString);
        setIsEditing(false);
        setIsModalOpen(true);
    };

    const closeModal = () => {
        setIsModalOpen(false);
        setSelectedNote(null);
        setIsEditing(false);
    };

    const updateNote = async (e) => {
        e.preventDefault();
        if (!selectedNote) return;
        try {
            const tagsList = editTags.split(',').map(t => t.trim()).filter(t => t);
            const response = await api.put(`/notes/${selectedNote.id}`, {
                title: editTitle,
                content: editContent,
                tags: tagsList
            });
            setSelectedNote(response.data);
            setIsEditing(false);
            fetchNotes();
            fetchAllTags();
        } catch (error) {
            console.error('Error updating note:', error);
        }
    };

    const deleteNote = (e, id) => {
        e.stopPropagation();
        if (window.confirm('Are you sure you want to delete this memory?')) {
            api.delete(`/notes/${id}`)
                .then(() => {
                    fetchNotes();
                    if (selectedNote && selectedNote.id === id) {
                        closeModal();
                    }
                })
                .catch(err => console.error(err));
        }
    };

    const analyzeNote = (e, noteId) => {
        e.stopPropagation();
        setAnalyzingNotes(prev => ({ ...prev, [noteId]: true }));

        api.post(`/notes/${noteId}/analyze`)
            .then(res => {
                const taskId = res.data.task_id;
                const interval = setInterval(async () => {
                    try {
                        const statusRes = await api.get(`/tasks/${taskId}/status`);
                        const { status } = statusRes.data;

                        if (status === 'SUCCESS' || status === 'FAILURE') {
                            clearInterval(interval);
                            setAnalyzingNotes(prev => {
                                const next = { ...prev };
                                delete next[noteId];
                                return next;
                            });

                            if (status === 'SUCCESS') {
                                fetchNotes();
                                if (selectedNote && selectedNote.id === noteId) {
                                    const updated = await api.get(`/notes/${noteId}`);
                                    setSelectedNote(updated.data);
                                }
                            } else {
                                const errorMsg = statusRes.data.error || 'Unknown error';
                                alert(`Analysis failed: ${errorMsg}`);
                            }
                        }
                    } catch (err) {
                        clearInterval(interval);
                        setAnalyzingNotes(prev => {
                            const next = { ...prev };
                            delete next[noteId];
                            return next;
                        });
                    }
                }, 2000);
            })
            .catch(err => {
                console.error(err);
                setAnalyzingNotes(prev => {
                    const next = { ...prev };
                    delete next[noteId];
                    return next;
                });
            });
    };

    const handleTagClick = (tagName) => {
        setSelectedTag(tagName);
        setSearchQuery('');
    };

    const clearFilter = () => {
        setSelectedTag(null);
    };

    if (authLoading) {
        return (
            <div className="loading-state">
                <div className="spinner"></div>
                <p>Syncing your memories...</p>
            </div>
        );
    }

    return (
        <div className="dashboard-container">
            <div className="main-content">
                {/* Header Section */}
                <header className="dashboard-header animate-in">
                    <div className="header-brand">
                        <span className="brand-dot">
                            <span className="brand-icon-inner">🧬</span>
                        </span>
                        <div className="header-meta">
                            <p className="subtitle">Secure Neural Vault</p>
                            <h1>Memories</h1>
                        </div>
                    </div>
                </header>

                {/* Create Note Form */}
                <section className="create-section animate-in">
                    <div className="card-glass create-card-premium">
                        <div className="card-accent" />
                        <div className="header-with-icon">
                            <h2>✨ New Memory</h2>
                        </div>
                        <form onSubmit={createNote} className="form-premium">
                            <input
                                type="text"
                                placeholder="Give it a title..."
                                value={title}
                                className="input-premium"
                                onChange={(e) => setTitle(e.target.value)}
                                required
                            />
                            <textarea
                                placeholder="What's on your mind? Capture the details..."
                                value={content}
                                className="textarea-premium"
                                onChange={(e) => setContent(e.target.value)}
                                required
                            />
                            <div className="form-row">
                                <input
                                    type="text"
                                    placeholder="Tags (comma separated)..."
                                    value={tags}
                                    className="input-premium tag-input"
                                    onChange={(e) => setTags(e.target.value)}
                                />
                                <button type="submit" className="btn-primary-premium">Save to Vault</button>
                            </div>
                        </form>
                    </div>
                </section>

                {/* Search & Filter */}
                <section className="search-section-premium animate-in">
                    <div className="search-bar-premium">
                        <span className="search-icon">🔍</span>
                        <input
                            type="text"
                            placeholder="Search your memories..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </div>
                    {selectedTag && (
                        <div className="active-filter-premium">
                            <span className="filter-label">Filtering:</span>
                            <span className="tag-pill-active">{selectedTag}</span>
                            <button onClick={clearFilter} className="clear-filter-btn">✕</button>
                        </div>
                    )}
                </section>

                {/* Tag Cloud */}
                {allTags.length > 0 && (
                    <section className="tag-cloud-premium animate-in">
                        <div className="section-header">
                            <h3>COLLECTIONS</h3>
                            <div className="header-line"></div>
                        </div>
                        <div className="tag-cloud-container">
                            {allTags.map(tag => (
                                <span
                                    key={tag.id}
                                    className={`tag-pill-explore ${selectedTag === tag.name ? 'active' : ''}`}
                                    onClick={() => handleTagClick(tag.name)}
                                >
                                    #{tag.name} <span className="tag-count">{tag.count}</span>
                                </span>
                            ))}
                        </div>
                    </section>
                )}

                {/* Notes Grid */}
                <section className="notes-grid-premium">
                    {notes.length === 0 ? (
                        <div className="empty-state animate-in">
                            <div className="empty-icon">📔</div>
                            <h3>No matches found</h3>
                            <p>Try a different search or create a new memory to get started.</p>
                        </div>
                    ) : (
                        notes.map(note => (
                            <NoteCard
                                key={note.id}
                                note={note}
                                onOpen={() => openNote(note)}
                                onTagClick={handleTagClick}
                                isAnalyzing={!!analyzingNotes[note.id]}
                            />
                        ))
                    )}
                </section>
            </div>

            {/* Modal */}
            {isModalOpen && selectedNote && (
                <div className="modal-overlay" onClick={closeModal}>
                    <div className="modal-content animate-in" onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <div className="header-content">
                                {isEditing ? (
                                    <input
                                        type="text"
                                        className="modal-title-input"
                                        value={editTitle}
                                        onChange={(e) => setEditTitle(e.target.value)}
                                    />
                                ) : (
                                    <div className="modal-title-container">
                                        <h2>{selectedNote.title}</h2>
                                        {selectedNote.sentiment && (
                                            <span className={`badge-sentiment ${selectedNote.sentiment.toLowerCase()}`}>
                                                {selectedNote.sentiment}
                                            </span>
                                        )}
                                    </div>
                                )}
                            </div>
                            <button className="close-btn" onClick={closeModal}>✕</button>
                        </div>

                        <div className="modal-body">
                            {isEditing ? (
                                <>
                                    <textarea
                                        className="modal-content-input"
                                        value={editContent}
                                        onChange={(e) => setEditContent(e.target.value)}
                                    />
                                    <input
                                        type="text"
                                        className="modal-tags-input"
                                        placeholder="Edit tags (comma separated)"
                                        value={editTags}
                                        onChange={(e) => setEditTags(e.target.value)}
                                    />
                                </>
                            ) : (
                                <>
                                    <div className="tags-container-modal">
                                        {selectedNote.tags && selectedNote.tags.map(tag => (
                                            <span
                                                key={tag.id}
                                                className="tag-item"
                                                onClick={() => {
                                                    handleTagClick(tag.name);
                                                    closeModal();
                                                }}
                                            >#{tag.name}</span>
                                        ))}
                                    </div>
                                    <div className="note-body-content">
                                        {selectedNote.content}
                                    </div>
                                </>
                            )}
                        </div>

                        <div className="modal-footer">
                            {isEditing ? (
                                <>
                                    <button onClick={updateNote} className="btn-primary-premium">Save Changes</button>
                                    <button onClick={() => setIsEditing(false)} className="btn-secondary-premium">Cancel</button>
                                </>
                            ) : (
                                <>
                                    <button
                                        onClick={(e) => analyzeNote(e, selectedNote.id)}
                                        className="btn-secondary-premium"
                                        disabled={!!analyzingNotes[selectedNote.id]}
                                    >
                                        {analyzingNotes[selectedNote.id] ? '⏳ Analyzing...' : '🤖 AI Analysis'}
                                    </button>
                                    <button onClick={() => setIsEditing(true)} className="btn-secondary-premium">✏️ Edit</button>
                                    <button onClick={(e) => deleteNote(e, selectedNote.id)} className="btn-danger-premium">🗑️ Delete</button>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Notes;
