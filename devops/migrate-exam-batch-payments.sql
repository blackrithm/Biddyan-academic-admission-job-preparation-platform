CREATE TABLE IF NOT EXISTS exam_batch_payment_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES exam_batches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(16) NOT NULL CHECK (provider IN ('bkash', 'nagad', 'rocket')),
    receiver_number VARCHAR(20) NOT NULL DEFAULT '01301051585',
    pay_type VARCHAR(20) NOT NULL DEFAULT 'send_money' CHECK (pay_type = 'send_money'),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount > 0),
    paid_from_number VARCHAR(20) NOT NULL,
    transaction_id VARCHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'failed')),
    review_note TEXT,
    reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_exam_batch_payment_transaction
    ON exam_batch_payment_requests (provider, UPPER(transaction_id));

CREATE UNIQUE INDEX IF NOT EXISTS idx_exam_batch_payment_one_pending
    ON exam_batch_payment_requests (batch_id, user_id)
    WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_exam_batch_payment_status_created
    ON exam_batch_payment_requests (status, created_at DESC);