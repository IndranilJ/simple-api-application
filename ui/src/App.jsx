import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

function App() {
  const [notes, setNotes] = useState([])
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')

  // Fetch notes on load
  useEffect(() => {
    fetchNotes()
  }, [])

  const fetchNotes = async () => {
    try {
      const response = await axios.get('/notes')
      setNotes(response.data)
    } catch (error) {
      console.error("Error fetching notes:", error)
    }
  }

  const createNote = async (e) => {
    e.preventDefault()
    try {
      await axios.post('/notes', { title, content })
      setTitle('')
      setContent('')
      fetchNotes() // Refresh list
    } catch (error) {
      console.error("Error creating note:", error)
    }
  }

  return (
    <div className="container">
      <h1>🧠 Synapse</h1>

      <div className="card">
        <h2>New Memory</h2>
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
          <button type="submit">Save Note</button>
        </form>
      </div>

      <div className="notes-grid">
        {notes.map(note => (
          <div key={note.id} className="note-card">
            <h3>{note.title}</h3>
            <p>{note.content}</p>
            <button onClick={() => analyzeNote(note.id)}
              style={{ marginTop: '10px', fontSize: '0.8em', backgroundColor: '#444' }}>
              🤖 Analyze
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}

function analyzeNote(id) {
  axios.post(`/notes/${id}/analyze`)
    .then(res => alert(`Task Started! ID: ${res.data.task_id}`))
    .catch(err => console.error(err))
}

export default App
