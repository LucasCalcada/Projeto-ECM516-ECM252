import { useState, useEffect } from 'react';
import './styles.css';

interface TimePickerProps {
  value: string; // HH:mm format
  onChange: (time: string) => void;
  minTime?: string;
  maxTime?: string;
  label?: string;
}

function splitTime(value: string) {
  const [h, m] = value.split(':');
  return {
    hours: h || '00',
    minutes: m || '00',
  };
}

export function TimePicker({ value, onChange, minTime, maxTime, label }: TimePickerProps) {
  const [{ hours, minutes }, setTimeParts] = useState(() => splitTime(value));
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      setTimeParts(splitTime(value));
    });

    return () => cancelAnimationFrame(frame);
  }, [value]);

  function handleHourChange(delta: number) {
    let newHour = parseInt(hours) + delta;

    if (minTime) {
      const [minH] = minTime.split(':');
      const minHourNum = parseInt(minH);
      if (newHour < minHourNum) newHour = minHourNum;
    }

    if (maxTime) {
      const [maxH] = maxTime.split(':');
      const maxHourNum = parseInt(maxH);
      if (newHour > maxHourNum) newHour = maxHourNum;
    }

    if (newHour < 0) newHour = 23;
    if (newHour > 23) newHour = 0;

    const newHourStr = String(newHour).padStart(2, '0');
    setTimeParts({ hours: newHourStr, minutes });
    updateTime(newHourStr, minutes);
  }

  function handleMinuteChange(delta: number) {
    let newMinute = parseInt(minutes) + delta;

    if (newMinute < 0) {
      newMinute = 59;
      handleHourChange(-1);
      return;
    }

    if (newMinute > 59) {
      newMinute = 0;
      handleHourChange(1);
      return;
    }

    const newMinuteStr = String(newMinute).padStart(2, '0');
    setTimeParts({ hours, minutes: newMinuteStr });
    updateTime(hours, newMinuteStr);
  }

  function updateTime(h: string, m: string) {
    onChange(`${h}:${m}`);
  }

  function handleDirectInput(type: 'hour' | 'minute', val: string) {
    if (type === 'hour') {
      let num = parseInt(val) || 0;
      if (num < 0) num = 0;
      if (num > 23) num = 23;
      const formatted = String(num).padStart(2, '0');
      setTimeParts({ hours: formatted, minutes });
      updateTime(formatted, minutes);
    } else {
      let num = parseInt(val) || 0;
      if (num < 0) num = 0;
      if (num > 59) num = 59;
      const formatted = String(num).padStart(2, '0');
      setTimeParts({ hours, minutes: formatted });
      updateTime(hours, formatted);
    }
  }

  return (
    <div className="time-picker-wrapper">
      {label && <label className="time-picker-label">{label}</label>}

      <div className="time-picker-container">
        <button type="button" className="time-picker-display" onClick={() => setIsOpen(!isOpen)}>
          <span className="time-display">
            {hours}:{minutes}
          </span>
          <span className="time-icon">🕐</span>
        </button>

        {isOpen && (
          <div className="time-picker-panel">
            <div className="time-picker-section">
              <div className="time-picker-label-section">Horas</div>

              <div className="time-input-group">
                <button
                  type="button"
                  className="spinner-btn up"
                  onClick={() => handleHourChange(1)}
                >
                  ▲
                </button>

                <input
                  type="number"
                  className="time-input"
                  value={hours}
                  onChange={(e) => handleDirectInput('hour', e.target.value)}
                  min="0"
                  max="23"
                />

                <button
                  type="button"
                  className="spinner-btn down"
                  onClick={() => handleHourChange(-1)}
                >
                  ▼
                </button>
              </div>
            </div>

            <div className="time-picker-divider">:</div>

            <div className="time-picker-section">
              <div className="time-picker-label-section">Minutos</div>

              <div className="time-input-group">
                <button
                  type="button"
                  className="spinner-btn up"
                  onClick={() => handleMinuteChange(1)}
                >
                  ▲
                </button>

                <input
                  type="number"
                  className="time-input"
                  value={minutes}
                  onChange={(e) => handleDirectInput('minute', e.target.value)}
                  min="0"
                  max="59"
                  step="5"
                />

                <button
                  type="button"
                  className="spinner-btn down"
                  onClick={() => handleMinuteChange(-1)}
                >
                  ▼
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
