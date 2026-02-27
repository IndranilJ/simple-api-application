import React from 'react';
import './NoteCard.css';

const NoteCard = ({ note, onOpen, onTagClick, isAnalyzing }) => {
    const sentimentClass = note.sentiment ? note.sentiment.toLowerCase() : '';

    const getSentimentIcon = (sentiment) => {
        switch (sentiment?.toLowerCase()) {
            case 'positive': return '✨';
            case 'negative': return '📉';
            case 'neutral': return '☁️';
            default: return '📝';
        }
    };

    return (
        <div className="note-card-glass animate-in" onClick={onOpen}>
            <div className="glass-shimmer" />
            <div className="card-content">
                <div className="card-header">
                    <div className="title-area">
                        <span className="sentiment-icon-mini">{getSentimentIcon(note.sentiment)}</span>
                        <h3>{note.title}</h3>
                    </div>
                    <div className="status-indicators">
                        {isAnalyzing ? (
                            <span className="badge-analyzing">
                                <span className="spinner-dots">...</span>
                            </span>
                        ) : note.sentiment && (
                            <span className={`badge-sentiment ${sentimentClass}`}>
                                {note.sentiment}
                            </span>
                        )}
                    </div>
                </div>

                <p className="truncated-content">{note.content}</p>

                <div className="card-footer">
                    <div className="note-tags">
                        {note.tags && note.tags.slice(0, 2).map(tag => (
                            <span
                                key={tag.id}
                                className="tag-item"
                                onClick={(e) => {
                                    e.stopPropagation();
                                    onTagClick(tag.name);
                                }}
                            >
                                #{tag.name}
                            </span>
                        ))}
                        {note.tags && note.tags.length > 2 && (
                            <span className="tag-more">+{note.tags.length - 2}</span>
                        )}
                    </div>
                    <div className="card-actions">
                        <button className="action-btn-mini">
                            <span className="action-icon">✏️</span>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default NoteCard;
