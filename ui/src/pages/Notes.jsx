import { useState, useEffect } from 'react';
import api from '../services/api';
import '../App.css'; // Reuse existing styles

const Notes = () => {
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

    useEffect(() => {
        fetchNotes();
        fetchAllTags();
    }, [searchQuery, selectedTag]);

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
        } catch (error) {
            console.error('Error updating note:', error);
        }
    };

    const deleteNote = (e, id) => {
        e.stopPropagation();
        if (confirm('Are you sure?')) {
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

    const analyzeNote = (e, id) => {
        e.stopPropagation();
        api.post(`/notes/${id}/analyze`)
            .then(res => alert(`Task Started! ID: ${res.data.task_id}`))
            .catch(err => console.error(err));
    };

    const handleTagClick = (tagName) => {
        setSelectedTag(tagName);
        setSearchQuery('');
    };

    const clearFilter = () => {
        setSelectedTag(null);
    };

    return (
        <div className="container" style={{ paddingTop: '2rem' }}>
            {/* Main Content Grid */}
            <div className="main-grid">
                {/* Create Form */}
                <div className="card create-card">
                    <h2>✨ New Memory</h2>
                    <form onSubmit={createNote}>
                        <input
                            type="text"
                            placeholder="Title"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            required
                        />
                        <textarea
                            placeholder="What's on your mind?"
                            value={content}
                            onChange={(e) => setContent(e.target.value)}
                            required
                        />
                        <input
                            type="text"
                            placeholder="Tags (comma separated, e.g. work, idea)"
                            value={tags}
                            onChange={(e) => setTags(e.target.value)}
                            style={{ marginBottom: '1rem' }}
                        />
                        <div className="btn-group">
                            <button type="submit" className="btn-primary">Save Note</button>
                        </div>
                    </form>
                </div>

                <div className="search-bar">
                    <input
                        type="text"
                        placeholder="🔍 Search notes..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                    {selectedTag && (
                        <div className="active-filter">
                            Filtered by: <span className="tag-pill active">{selectedTag}</span>
                            <button onClick={clearFilter} className="clear-filter-btn">✕ Clear</button>
                        </div>
                    )}
                </div>

                {/* Tag Cloud */}
                {allTags.length > 0 && (
                    <div className="tag-cloud">
                        <h3>Filter by Tag:</h3>
                        <div className="tag-cloud-container">
                            {allTags.map(tag => (
                                <span
                                    key={tag.id}
                                    className={`tag-pill clickable ${selectedTag === tag.name ? 'active' : ''}`}
                                    onClick={() => handleTagClick(tag.name)}
                                >
                                    {tag.name} <span className="tag-count">({tag.count})</span>
                                </span>
                            ))}
                        </div>
                    </div>
                )}

                {/* Notes Grid */}
                <div className="notes-grid">
                    {notes.length === 0 && <p style={{ color: '#888', gridColumn: '1/-1', textAlign: 'center' }}>No memories found. Create one!</p>}
                    {notes.map(note => (
                        <div key={note.id} className="note-card" onClick={() => openNote(note)}>
                            <div>
                                <h3>
                                    {note.title}
                                    {note.sentiment && <span className="badge">{note.sentiment}</span>}
                                </h3>
                                <div className="tags-container">
                                    {note.tags && note.tags.map(tag => (
                                        <span
                                            key={tag.id}
                                            className="tag-pill clickable"
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleTagClick(tag.name);
                                            }}
                                        >{tag.name}</span>
                                    ))}
                                </div>
                                <p className="note-content truncated">{note.content}</p>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Modal */}
            {isModalOpen && selectedNote && (
                <div className="modal-overlay" onClick={closeModal}>
                    <div className="modal-content" onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            {isEditing ? (
                                <div style={{ width: '100%' }}>
                                    <input
                                        type="text"
                                        className="modal-title-input"
                                        value={editTitle}
                                        onChange={(e) => setEditTitle(e.target.value)}
                                    />
                                </div>
                            ) : (
                                <h2>
                                    {selectedNote.title}
                                    {selectedNote.sentiment && <span className="badge" style={{ verticalAlign: 'middle', marginLeft: '10px' }}>{selectedNote.sentiment}</span>}
                                </h2>
                            )}
                            <button className="close-btn" onClick={closeModal}>&times;</button>
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
                                        placeholder="Tags (comma separated)"
                                        value={editTags}
                                        onChange={(e) => setEditTags(e.target.value)}
                                    />
                                </>
                            ) : (
                                <>
                                    <div className="tags-container" style={{ marginBottom: '1rem' }}>
                                        {selectedNote.tags && selectedNote.tags.map(tag => (
                                            <span
                                                key={tag.id}
                                                className="tag-pill clickable"
                                                onClick={() => {
                                                    handleTagClick(tag.name);
                                                    closeModal();
                                                }}
                                            >{tag.name}</span>
                                        ))}
                                    </div>
                                    <p>{selectedNote.content}</p>
                                </>
                            )}
                        </div>

                        <div className="modal-footer">
                            {isEditing ? (
                                <>
                                    <button onClick={updateNote} className="btn-primary">Save Changes</button>
                                    <button onClick={() => setIsEditing(false)} className="btn-secondary">Cancel</button>
                                </>
                            ) : (
                                <>
                                    <button onClick={(e) => analyzeNote(e, selectedNote.id)} className="btn-secondary">🤖 Analyze</button>
                                    <button onClick={() => setIsEditing(true)} className="btn-secondary">✏️ Edit</button>
                                    <button onClick={(e) => deleteNote(e, selectedNote.id)} className="btn-danger">🗑️ Delete</button>
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
