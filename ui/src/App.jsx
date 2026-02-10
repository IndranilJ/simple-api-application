import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

function App() {
  // Theme state
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem('theme') || 'dark'
  })

  const [notes, setNotes] = useState([])
  const [allTags, setAllTags] = useState([])

  // Main create form state
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [tags, setTags] = useState('') // New state
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedTag, setSelectedTag] = useState(null) // Filter by tag

  // Modal State
  const [selectedNote, setSelectedNote] = useState(null)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isEditing, setIsEditing] = useState(false)

  // Edit form state (inside modal)
  const [editTitle, setEditTitle] = useState('')
  const [editContent, setEditContent] = useState('')
  const [editTags, setEditTags] = useState('') // New state

  // Apply theme on mount and when it changes
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('theme', theme)
  }, [theme])

  const toggleTheme = () => {
    setTheme(prevTheme => prevTheme === 'dark' ? 'light' : 'dark')
  }

  useEffect(() => {
    fetchNotes()
    fetchAllTags()
  }, [searchQuery, selectedTag])

  const fetchNotes = async () => {
    try {
      const params = {}
      if (searchQuery) params.q = searchQuery
      if (selectedTag) params.tag = selectedTag

      const response = await axios.get('/notes', { params })
      setNotes(response.data)
    } catch (error) {
      console.error("Error fetching notes:", error)
    }
  }

  const handleTagClick = (tagName) => {
    setSelectedTag(tagName)
    setSearchQuery('') // Clear search when filtering by tag
  }

  const clearFilter = () => {
    setSelectedTag(null)
  }

  const fetchAllTags = async () => {
    try {
      const response = await axios.get('/tags')
      // Ensure it's always an array
      setAllTags(Array.isArray(response.data) ? response.data : [])
    } catch (error) {
      console.error("Error fetching tags:", error)
      setAllTags([]) // Ensure it's an empty array on error
    }
  }

  // Create New Note
  const createNote = async (e) => {
    e.preventDefault()
    try {
      // Convert comma-separated string to array
      const tagsList = tags.split(',').map(t => t.trim()).filter(t => t)

      await axios.post('/notes', { title, content, tags: tagsList })
      setTitle('')
      setContent('')
      setTags('')
      fetchNotes()
      fetchAllTags() // Refresh tag cloud
    } catch (error) {
      console.error("Error creating note:", error)
    }
  }

  // Open Modal
  const openNote = (note) => {
    setSelectedNote(note)
    setEditTitle(note.title)
    setEditContent(note.content)
    // Convert array of objects to comma-separated string
    const tagString = note.tags ? note.tags.map(t => t.name).join(', ') : ''
    setEditTags(tagString)

    setIsEditing(false)
    setIsModalOpen(true)
  }

  // Close Modal
  const closeModal = () => {
    setIsModalOpen(false)
    setSelectedNote(null)
    setIsEditing(false)
  }

  // Update Note (from Modal)
  const updateNote = async (e) => {
    e.preventDefault()
    if (!selectedNote) return

    try {
      const tagsList = editTags.split(',').map(t => t.trim()).filter(t => t)

      const response = await axios.put(`/notes/${selectedNote.id}`, {
        title: editTitle,
        content: editContent,
        tags: tagsList
      })

      // Update local state to reflect changes immediately
      // The API returns the updated note with tags
      setSelectedNote(response.data)
      setIsEditing(false)

      fetchNotes() // Refresh list in background
    } catch (error) {
      console.error("Error updating note:", error)
    }
  }

  const deleteNote = (e, id) => {
    e.stopPropagation()
    if (confirm("Are you sure?")) {
      axios.delete(`/notes/${id}`)
        .then(() => {
          fetchNotes()
          if (selectedNote && selectedNote.id === id) {
            closeModal()
          }
        })
        .catch(err => console.error(err))
    }
  }

  const analyzeNote = (e, id) => {
    e.stopPropagation()
    axios.post(`/notes/${id}/analyze`)
      .then(res => alert(`Task Started! ID: ${res.data.task_id}`))
      .catch(err => console.error(err))
  }

  return (
    <>
      {/* Theme Toggle Button */}
      <button className="theme-toggle" onClick={toggleTheme} aria-label="Toggle theme">
        <span className="theme-icon">
          {theme === 'dark' ? '☀️' : '🌙'}
        </span>
      </button>

      <div className="container">
        {/* Hero Section */}
        <div className="hero">
          <div className="hero-icon">🧠</div>
          <h1 className="hero-title">Synapse</h1>
          <p className="hero-subtitle">Your intelligent memory companion</p>
        </div>

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
                <button type="submit" className="btn-primary">
                  Save Note
                </button>
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
              <div
                key={note.id}
                className="note-card"
                onClick={() => openNote(note)}
              >
                <div>
                  <h3>
                    {note.title}
                    {note.sentiment && <span className="badge">
                      {note.sentiment}
                    </span>}
                  </h3>
                  <div className="tags-container">
                    {note.tags && note.tags.map(tag => (
                      <span
                        key={tag.id}
                        className="tag-pill clickable"
                        onClick={(e) => {
                          e.stopPropagation()
                          handleTagClick(tag.name)
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
        {/* End Main Grid */}
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
                          handleTagClick(tag.name)
                          closeModal()
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
    </>
  )
}

export default App
